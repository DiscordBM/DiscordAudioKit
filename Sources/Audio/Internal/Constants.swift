// sample rate required by discord voice (48 khz)
public let discordSampleRate: Int = 48000

// channel count for standard discord stereo audio
public let discordChannelCount: Int = 2

// duration of one standard discord audio frame in milliseconds
public let discordFrameDurationMs: Int = 20

// samples per channel in one 20 ms frame (48000 * 20 / 1000 = 960)
public let discordSamplesPerChannel: Int = 960

// total interleaved samples in one stereo 20 ms frame (960 * 2 = 1920)
public let discordFrameSampleCount: Int = 1920

// standard 3-byte opus silence packet defined by discord
public let discordSilencePacket: [UInt8] = [0xF8, 0xFF, 0xFE]

// package constants enum for namespace clarity
public enum AudioConstants {
    public static let sampleRate: Int = 48000
    public static let channelCount: Int = 2
    public static let frameDurationMs: Int = 20
    public static let samplesPerChannelPerFrame: Int = 960
    public static let frameSampleCount: Int = 1920
    public static let maxFrameSizePerChannel: Int = 5760
    public static let silencePacket: [UInt8] = [0xF8, 0xFF, 0xFE]
}
