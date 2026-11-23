import Foundation
import Testing

@testable import Audio

@Suite("AudioDecoder")
struct AudioDecoderTests {

    @Test
    func wavInMemoryDecode() throws {
        let wavBytes = WavBuilder.buildSine(
            frequency: 440.0,
            sampleRate: 48000,
            frames: 9600,
            channels: 2
        )
        let decoder = try AudioDecoder(bytes: wavBytes)
        #expect(decoder.info.sourceSampleRate == 48000)
        #expect(decoder.info.sourceChannels == 2)
        #expect(decoder.info.lengthInFrames == 9600)

        var allSamples = [Float]()
        while true {
            let chunk = try decoder.read(frames: 960)
            if chunk.isEmpty { break }
            allSamples.append(contentsOf: chunk)
        }

        #expect(allSamples.count == 9600 * 2)

        // check frequency power via goertzel
        let power440 = Goertzel.power(
            interleavedSamples: allSamples,
            channels: 2,
            sampleRate: 48000,
            targetFrequency: 440.0
        )
        let power1000 = Goertzel.power(
            interleavedSamples: allSamples,
            channels: 2,
            sampleRate: 48000,
            targetFrequency: 1000.0
        )
        #expect(power440 > 0.05)
        #expect(power440 > power1000 * 100.0)
    }

    @Test
    func mp3FixtureDecode() throws {
        let path = FixtureLoader.path(named: "sine440.mp3")
        let decoder = try AudioDecoder(path: path)
        #expect(decoder.info.sourceSampleRate == 48000)
        #expect(decoder.info.sourceChannels == 2)

        var allSamples = [Float]()
        while true {
            let chunk = try decoder.read(frames: 960)
            if chunk.isEmpty { break }
            allSamples.append(contentsOf: chunk)
        }

        #expect(!allSamples.isEmpty)
        let power440 = Goertzel.power(
            interleavedSamples: allSamples,
            channels: 2,
            sampleRate: 48000,
            targetFrequency: 440.0
        )
        #expect(power440 > 0.01)
    }

    @Test
    func flacFixtureDecode() throws {
        let path = FixtureLoader.path(named: "sine440.flac")
        let decoder = try AudioDecoder(path: path)
        #expect(decoder.info.sourceSampleRate == 48000)
        #expect(decoder.info.sourceChannels == 2)

        var allSamples = [Float]()
        while true {
            let chunk = try decoder.read(frames: 960)
            if chunk.isEmpty { break }
            allSamples.append(contentsOf: chunk)
        }

        #expect(!allSamples.isEmpty)
        let power440 = Goertzel.power(
            interleavedSamples: allSamples,
            channels: 2,
            sampleRate: 48000,
            targetFrequency: 440.0
        )
        #expect(power440 > 0.05)
    }

    @Test
    func streamingInputSequentialRead() throws {
        let wavBytes = WavBuilder.buildSine(
            frequency: 440.0,
            sampleRate: 48000,
            frames: 1920,
            channels: 2
        )
        let lock = TestLock(initialState: 0)
        let decoder = try AudioDecoder(
            input: .stream(
                read: { bytesToRead in
                    lock.withLock { cursor in
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

        var totalRead = 0
        while true {
            let chunk = try decoder.read(frames: 480)
            if chunk.isEmpty { break }
            totalRead += chunk.count
        }

        #expect(totalRead == 1920 * 2)

        // non-seekable stream must fail seeking
        #expect(throws: AudioError.self) {
            try decoder.seek(toFrame: 0)
        }
    }

    @Test
    func seekForwardAndBackward() throws {
        let wavBytes = WavBuilder.buildSine(
            frequency: 440.0,
            sampleRate: 48000,
            frames: 9600,
            channels: 2
        )
        let decoder = try AudioDecoder(bytes: wavBytes)

        let initialChunk = try decoder.read(frames: 960)
        #expect(initialChunk.count == 1920)

        // seek forward
        try decoder.seek(toFrame: 4800)
        let midChunk = try decoder.read(frames: 960)
        #expect(midChunk.count == 1920)

        // seek back to start
        try decoder.seek(toFrame: 0)
        let rewindChunk = try decoder.read(frames: 960)
        #expect(rewindChunk == initialChunk)
    }

    @Test
    func closedDecoderThrows() throws {
        let wavBytes = WavBuilder.buildSine(
            frequency: 440.0,
            sampleRate: 48000,
            frames: 960,
            channels: 2
        )
        let decoder = try AudioDecoder(bytes: wavBytes)
        decoder.close()
        #expect(decoder.isClosed)

        // second close is safe
        decoder.close()

        #expect(throws: AudioError.closed) {
            _ = try decoder.read(frames: 960)
        }
        #expect(throws: AudioError.closed) {
            try decoder.seek(toFrame: 0)
        }
    }

    @Test
    func corruptedDataThrows() {
        let corrupted: [UInt8] = [0x52, 0x49, 0x46, 0x46, 0x00, 0x00]
        #expect(throws: AudioError.self) {
            try AudioDecoder(bytes: corrupted)
        }
    }
}
