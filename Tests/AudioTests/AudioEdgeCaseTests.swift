import Testing

@testable import Audio

@Suite("AudioEdgeCaseTests")
struct AudioEdgeCaseTests {

    @Test
    func longStreamingThroughNonSeekableStream() throws {
        // synthesize 5 seconds of 48khz stereo audio = 240,000 pcm frames = 480,000 floats
        let totalPcmFrames = 48000 * 5
        let samples = SineWave.generate(frequency: 440.0, frames: totalPcmFrames, channels: 2)
        let wavBytes = WavBuilder.build(sampleRate: 48000, channels: 2, samples: samples)

        let streamLock = TestLock(initialState: 0)
        let decoder = try AudioDecoder(
            input: .stream(
                read: { bytesToRead in
                    streamLock.withLock { cursor in
                        guard cursor < wavBytes.count else { return [] }
                        let count = min(bytesToRead, wavBytes.count - cursor)
                        let slice = Array(wavBytes[cursor..<(cursor + count)])
                        cursor += count
                        return slice
                    }
                },
                seek: nil
            )
        )

        var totalDecodedFloats = 0
        while true {
            let chunk = try decoder.read(frames: 960)
            if chunk.isEmpty { break }
            totalDecodedFloats += chunk.count
        }

        #expect(totalDecodedFloats == totalPcmFrames * 2)
    }

    @Test
    func primeNumberChunkingInFrameChunker() {
        var chunker = FrameChunker(channels: 2)
        let primeSizes = [7, 13, 29, 71, 137, 283, 521, 997, 1009]

        var totalPushedSamples = 0
        var totalExtractedFrames: [[Float]] = []

        for size in primeSizes {
            let chunk = [Float](repeating: 0.1, count: size)
            totalPushedSamples += size
            totalExtractedFrames.append(contentsOf: chunker.push(chunk))
        }

        let fullExpectedFrames = totalPushedSamples / 1920
        #expect(totalExtractedFrames.count == fullExpectedFrames)
        for frame in totalExtractedFrames {
            #expect(frame.count == 1920)
        }

        let remainder = totalPushedSamples % 1920
        #expect(chunker.bufferedSampleCount == remainder)

        if remainder > 0 {
            let finalFrame = chunker.finish(padWithSilence: true)
            #expect(finalFrame != nil)
            #expect(finalFrame?.count == 1920)
            #expect(chunker.isEmpty)
        }
    }

    @Test
    func reconfigureEncoderMidStream() throws {
        let encoder = try OpusEncoder(channels: 2, configuration: .music)
        let frame1 = SineWave.generate(frequency: 440.0, frames: 960, channels: 2)
        let packet1 = try encoder.encode(frame: frame1)
        #expect(!packet1.bytes.isEmpty)

        // reconfigure to voip with 64kbps, dtx, fec
        let newConfig = try OpusConfiguration(
            application: .voip,
            bitrate: 64_000,
            complexity: 5,
            fec: true,
            dtx: true,
            expectedPacketLossPercent: 10
        )
        try encoder.reconfigure(newConfig)
        #expect(encoder.configuration.bitrate == 64_000)
        #expect(encoder.configuration.dtx)
        #expect(encoder.configuration.fec)

        let frame2 = SineWave.generate(frequency: 880.0, frames: 960, channels: 2)
        let packet2 = try encoder.encode(frame: frame2)
        #expect(!packet2.bytes.isEmpty)
        #expect(packet2.channels == 2)
    }

    @Test
    func opusLossConcealmentBoundaries() throws {
        let decoder = try OpusDecoder(channels: 2)

        // valid concealment frame sizes
        let validSizes = [120, 240, 480, 960, 1920, 2880, 5760]
        for size in validSizes {
            let pcm = try decoder.decodeLoss(frames: size)
            #expect(pcm.count == size * 2)
        }

        // invalid frame sizes must throw
        #expect(throws: AudioError.self) {
            _ = try decoder.decodeLoss(frames: 0)
        }
        #expect(throws: AudioError.self) {
            _ = try decoder.decodeLoss(frames: -1)
        }
        #expect(throws: AudioError.self) {
            _ = try decoder.decodeLoss(frames: 5761)
        }
    }

    @Test
    func invalidSeekThrowsAudioError() throws {
        let samples = SineWave.generate(frequency: 440.0, frames: 1920, channels: 2)
        let wav = WavBuilder.build(sampleRate: 48000, channels: 2, samples: samples)
        let decoder = try AudioDecoder(bytes: wav)

        // negative frame index
        #expect(throws: AudioError.self) {
            try decoder.seek(toFrame: -10)
        }

        // seeking after close throws closed
        decoder.close()
        #expect(throws: AudioError.self) {
            try decoder.seek(toFrame: 0)
        }
    }

    @Test
    func multipleCloseIsIdempotentAcrossAllTypes() throws {
        let samples = SineWave.generate(frequency: 440.0, frames: 1920, channels: 2)
        let wav = WavBuilder.build(sampleRate: 48000, channels: 2, samples: samples)

        let decoder = try AudioDecoder(bytes: wav)
        decoder.close()
        decoder.close()
        #expect(decoder.isClosed)

        let encoder = try OpusEncoder(channels: 2)
        encoder.close()
        encoder.close()
        #expect(encoder.isClosed)

        let opusDecoder = try OpusDecoder(channels: 2)
        opusDecoder.close()
        opusDecoder.close()
        #expect(opusDecoder.isClosed)

        let streamDecoder = try AudioDecoder(bytes: wav)
        let stream = try OpusPacketStream(streamDecoder)
        stream.close()
        stream.close()
        #expect(stream.isClosed)
        #expect(streamDecoder.isClosed)
    }

    @Test
    func truncatedWavHeadersThrowCleanly() {
        // fewer than 44 bytes
        let truncated1: [UInt8] = [0x52, 0x49, 0x46, 0x46, 0x10, 0x00]
        #expect(throws: AudioError.self) {
            _ = try AudioDecoder(bytes: truncated1)
        }

        // RIFF header without WAVE
        let badHeader: [UInt8] = Array(repeating: 0x00, count: 64)
        #expect(throws: AudioError.self) {
            _ = try AudioDecoder(bytes: badHeader)
        }
    }
}
