import Testing

@testable import Audio

@Suite("Audio Toolchain Smoke")
struct ToolchainSmokeTests {

    @Test
    func discordConstantsMatchVoiceSpecification() {
        #expect(discordSampleRate == 48000)
        #expect(discordChannelCount == 2)
        #expect(discordFrameDurationMs == 20)
        #expect(discordSamplesPerChannel == 960)
        #expect(discordFrameSampleCount == 1920)
    }

    @Test
    func frameSampleMathIsConsistent() {
        let expectedPerChannel = (discordSampleRate * discordFrameDurationMs) / 1000
        #expect(expectedPerChannel == discordSamplesPerChannel)

        let expectedTotal = expectedPerChannel * discordChannelCount
        #expect(expectedTotal == discordFrameSampleCount)
    }

    @Test
    func silencePacketMatchesDiscordOpusBytes() {
        #expect(discordSilencePacket.count == 3)
        #expect(discordSilencePacket == [0xF8, 0xFF, 0xFE])
    }
}
