import Testing

@testable import Audio

@Suite("OpusPacketStream")
struct OpusPacketStreamTests {

    @Test
    func streamYieldsExpectedPacketCount() async throws {
        // 48000 frames is exactly 1 second, which equals 50 20ms frames
        let samples = SineWave.generate(frequency: 440.0, frames: 48000, channels: 2)
        let wav = WavBuilder.build(sampleRate: 48000, channels: 2, samples: samples)
        let decoder = try AudioDecoder(bytes: wav)
        let stream = try OpusPacketStream(decoder, configuration: .music)

        var packetCount = 0
        for try await packet in stream {
            packetCount += 1
            #expect(packet.channels == 2)
            #expect(packet.durationMilliseconds == 20.0)
            #expect(!packet.bytes.isEmpty)
        }

        #expect(packetCount == 50)
    }

    @Test
    func streamPacketsDecodeBackToSource() async throws {
        let original = SineWave.generate(frequency: 440.0, frames: 960 * 10, channels: 2)
        let wav = WavBuilder.build(sampleRate: 48000, channels: 2, samples: original)
        let decoder = try AudioDecoder(bytes: wav)
        let stream = try OpusPacketStream(decoder, configuration: .music)
        let opusDecoder = try OpusDecoder(channels: 2)

        var decodedSamples: [Float] = []
        for try await packet in stream {
            let pcm = try opusDecoder.decode(packet: packet)
            decodedSamples.append(contentsOf: pcm)
        }

        #expect(decodedSamples.count == original.count)

        // correlation accounts for codec delay lookahead
        let result = Correlation.best(reference: original, signal: decodedSamples, maxLag: 960)
        #expect(result.score > 0.95)
    }

    @Test
    func synchronousNextOnClock() throws {
        let samples = SineWave.generate(frequency: 880.0, frames: 1920 * 5, channels: 2)
        let wav = WavBuilder.build(sampleRate: 48000, channels: 2, samples: samples)
        let decoder = try AudioDecoder(bytes: wav)
        let stream = try OpusPacketStream(decoder, configuration: .voip)

        var packets: [OpusPacket] = []
        while let packet = try stream.next() {
            packets.append(packet)
        }

        #expect(packets.count == 10)
        #expect(try stream.next() == nil)
    }

    @Test
    func pullBasedDecoding() throws {
        let readCalls = TestLock(initialState: 0)
        let samples = SineWave.generate(frequency: 440.0, frames: 960 * 2, channels: 2)
        let wav = WavBuilder.build(sampleRate: 48000, channels: 2, samples: samples)

        let streamLock = TestLock(initialState: 0)
        let decoder = try AudioDecoder(
            input: .stream(
                read: { count in
                    readCalls.withLock { $0 += 1 }
                    return streamLock.withLock { offset in
                        guard offset < wav.count else { return [] }
                        let end = min(offset + count, wav.count)
                        let chunk = Array(wav[offset..<end])
                        offset = end
                        return chunk
                    }
                },
                seek: nil
            )
        )

        let initialReads = readCalls.withLock { $0 }
        let stream = try OpusPacketStream(decoder, configuration: .music)
        // creating stream did not read more data
        #expect(readCalls.withLock { $0 } == initialReads)

        // pulling one packet reads only what is needed
        let packet1 = try stream.next()
        #expect(packet1 != nil)
        let readsAfterFirst = readCalls.withLock { $0 }
        #expect(readsAfterFirst > initialReads)

        let packet2 = try stream.next()
        #expect(packet2 != nil)
        #expect(readCalls.withLock { $0 } >= readsAfterFirst)
    }

    @Test
    func cancellationStopsWorkAndFreesNativeObjects() async throws {
        let samples = SineWave.generate(frequency: 440.0, frames: 48000 * 2, channels: 2)
        let wav = WavBuilder.build(sampleRate: 48000, channels: 2, samples: samples)

        let result = try await withThrowingTaskGroup(of: (Int, Bool, Bool).self) { group in
            group.addTask {
                let decoder = try AudioDecoder(bytes: wav)
                let stream = try OpusPacketStream(decoder, configuration: .music)
                var count = 0
                for try await _ in stream {
                    count += 1
                }
                return (count, stream.isClosed, decoder.isClosed)
            }
            group.cancelAll()
            return try await group.next()
        }

        #expect(result != nil)
        if let (count, isStreamClosed, isDecoderClosed) = result {
            #expect(count < 50)
            #expect(isStreamClosed)
            #expect(isDecoderClosed)
        }
    }

    @Test
    func closedStreamThrows() throws {
        let samples = SineWave.generate(frequency: 440.0, frames: 960, channels: 2)
        let wav = WavBuilder.build(sampleRate: 48000, channels: 2, samples: samples)
        let decoder = try AudioDecoder(bytes: wav)
        let stream = try OpusPacketStream(decoder, configuration: .music)

        stream.close()
        #expect(stream.isClosed)
        #expect(throws: AudioError.self) {
            _ = try stream.next()
        }
    }
}
