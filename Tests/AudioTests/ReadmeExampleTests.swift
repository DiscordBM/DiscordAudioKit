import Testing

@testable import Audio

@Suite("ReadmeExample")
struct ReadmeExampleTests {

    @Test
    func readmeExampleRuns() async throws {
        // 960 frames per channel = 20ms stereo frame
        let samples = SineWave.generate(frequency: 440.0, frames: 960, channels: 2)
        let wavBytes = WavBuilder.build(sampleRate: 48000, channels: 2, samples: samples)

        let decoder = try AudioDecoder(bytes: wavBytes)
        let packets = try OpusPacketStream(decoder, configuration: .music)

        var packetCount = 0
        for try await packet in packets {
            #expect(!packet.bytes.isEmpty)
            #expect(packet.channels == 2)
            #expect(packet.durationMilliseconds == 20.0)
            packetCount += 1
        }
        #expect(packetCount == 1)
    }
}
