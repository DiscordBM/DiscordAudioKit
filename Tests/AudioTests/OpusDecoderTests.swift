import Foundation
import Testing

@testable import Audio

@Suite("OpusDecoder")
struct OpusDecoderTests {

    @Test
    func decodeSilencePacket() throws {
        let decoder = try OpusDecoder(channels: 2)
        #expect(!decoder.isClosed)

        let pcm = try decoder.decode(packet: .silence)
        #expect(pcm.count == 1920)
    }

    @Test
    func sineWaveRoundtripCorrelation() throws {
        let encoder = try OpusEncoder(channels: 2, configuration: .music)
        let decoder = try OpusDecoder(channels: 2)

        // encode 5 consecutive frames (100 ms total) to establish codec state
        var referenceAudio = [Float]()
        var decodedAudio = [Float]()

        let framesPerChunk = 960
        let totalChunks = 5

        for chunk in 0..<totalChunks {
            let startFrame = chunk * framesPerChunk
            var framePcm = [Float]()
            framePcm.reserveCapacity(framesPerChunk * 2)

            for i in 0..<framesPerChunk {
                let t = Double(startFrame + i) / 48000.0
                let sample = Float(0.5 * sin(2.0 * Double.pi * 440.0 * t))
                framePcm.append(sample)
                framePcm.append(sample)
            }

            referenceAudio.append(contentsOf: framePcm)
            let packet = try encoder.encode(frame: framePcm)
            let decodedFrame = try decoder.decode(packet: packet)
            decodedAudio.append(contentsOf: decodedFrame)
        }

        #expect(decodedAudio.count == referenceAudio.count)

        // verify high correlation after accounting for codec lookahead delay
        let result = Correlation.best(
            reference: referenceAudio,
            signal: decodedAudio,
            maxLag: 960
        )
        // opus compression of pure sine tone matches above 0.95 cross-correlation
        #expect(result.score > 0.95)
    }

    @Test
    func lossConcealmentReturnsFrameSize() throws {
        let decoder = try OpusDecoder(channels: 2)
        let concealed = try decoder.decodeLoss(frames: 960)
        #expect(concealed.count == 1920)
    }

    @Test
    func emptyBytesThrows() throws {
        let decoder = try OpusDecoder(channels: 2)
        #expect(throws: AudioError.self) {
            try decoder.decode(bytes: [])
        }
    }

    @Test
    func corruptedBytesThrows() throws {
        let decoder = try OpusDecoder(channels: 2)
        // invalid arbitrary payload
        let garbage: [UInt8] = [0xFF, 0x00, 0xAA, 0xBB]
        #expect(throws: AudioError.self) {
            try decoder.decode(bytes: garbage)
        }
    }

    @Test
    func closedDecoderThrows() throws {
        let decoder = try OpusDecoder(channels: 2)
        decoder.close()
        #expect(decoder.isClosed)

        decoder.close()

        #expect(throws: AudioError.closed) {
            try decoder.decode(packet: .silence)
        }
    }
}
