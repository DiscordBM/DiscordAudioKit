import Testing

@testable import Audio

@Suite("OpusPacket")
struct OpusPacketTests {

    @Test
    func silencePacketProperties() {
        let packet = OpusPacket.silence
        #expect(packet.bytes == AudioConstants.silencePacket)
        #expect(packet.channels == 1)
        #expect(packet.frameCount == 1)
        #expect(packet.samplesPerFrame == 960)
        #expect(packet.totalSamples == 960)
        #expect(packet.durationMilliseconds == 20.0)
    }

    @Test
    func emptyBytesThrows() {
        #expect(throws: AudioError.self) {
            try OpusPacket(bytes: [])
        }
    }

    @Test
    func invalidBytesThrows() {
        // code 3 packet requires at least 2 bytes (toc + frame count byte)
        #expect(throws: AudioError.self) {
            try OpusPacket(bytes: [0x03])
        }
    }

    @Test
    func equalityAndHashing() throws {
        let p1 = try OpusPacket(bytes: AudioConstants.silencePacket)
        let p2 = try OpusPacket(bytes: AudioConstants.silencePacket)
        #expect(p1 == p2)
    }
}
