import Testing

@testable import Audio

@Suite("OpusEncoder")
struct OpusEncoderTests {

    @Test
    func encodeStereoFrameSuccess() throws {
        let encoder = try OpusEncoder(channels: 2, configuration: .music)
        #expect(!encoder.isClosed)

        let pcm = SineWave.generate(frequency: 440.0, frames: 960, channels: 2)
        #expect(pcm.count == 1920)

        let packet = try encoder.encode(frame: pcm)
        #expect(!packet.bytes.isEmpty)
        #expect(packet.channels == 2)
        #expect(packet.samplesPerFrame == 960)
        #expect(packet.durationMilliseconds == 20.0)
    }

    @Test
    func encodeMonoFrameSuccess() throws {
        let encoder = try OpusEncoder(channels: 1, configuration: .voip)
        #expect(encoder.channels == 1)

        let pcm = SineWave.generate(frequency: 440.0, frames: 960, channels: 1)
        #expect(pcm.count == 960)

        let packet = try encoder.encode(frame: pcm)
        #expect(!packet.bytes.isEmpty)
        #expect(packet.channels == 1)
        #expect(packet.samplesPerFrame == 960)
    }

    @Test
    func wrongSampleCountThrows() throws {
        let encoder = try OpusEncoder(channels: 2)
        let shortFrame = [Float](repeating: 0.0, count: 500)

        #expect(throws: AudioError.self) {
            try encoder.encode(frame: shortFrame)
        }
    }

    @Test
    func invalidChannelCountThrows() {
        #expect(throws: AudioError.self) {
            try OpusEncoder(channels: 3)
        }
    }

    @Test
    func silenceEncodesToSmallPacket() throws {
        let encoder = try OpusEncoder(channels: 2)
        let silencePcm = [Float](repeating: 0.0, count: 1920)

        let packet = try encoder.encode(frame: silencePcm)
        #expect(packet.bytes.count < 100)
    }

    @Test
    func lookaheadAndReconfigure() throws {
        let encoder = try OpusEncoder(channels: 2, configuration: .music)
        let lookahead = try encoder.lookahead
        #expect(lookahead > 0)

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
        #expect(encoder.configuration.complexity == 5)
    }

    @Test
    func closedEncoderThrows() throws {
        let encoder = try OpusEncoder(channels: 2)
        encoder.close()
        #expect(encoder.isClosed)

        // redundant close is safe
        encoder.close()

        let pcm = [Float](repeating: 0.0, count: 1920)
        #expect(throws: AudioError.closed) {
            try encoder.encode(frame: pcm)
        }
    }
}
