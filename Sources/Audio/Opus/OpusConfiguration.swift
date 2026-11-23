import COpus

public struct OpusConfiguration: Sendable, Equatable {

    public enum Application: Sendable, Equatable {
        case voip
        case music
        case lowDelay

        var rawValue: Int32 {
            switch self {
            case .voip:
                return OPUS_APPLICATION_VOIP
            case .music:
                return OPUS_APPLICATION_AUDIO
            case .lowDelay:
                return OPUS_APPLICATION_RESTRICTED_LOWDELAY
            }
        }
    }

    public var application: Application
    public var bitrate: Int
    public var complexity: Int
    public var fec: Bool
    public var dtx: Bool
    public var expectedPacketLossPercent: Int

    public static let voip = OpusConfiguration(
        uncheckedApplication: .voip,
        bitrate: 64_000,
        complexity: 10,
        fec: true,
        dtx: false,
        expectedPacketLossPercent: 0
    )

    public static let music = OpusConfiguration(
        uncheckedApplication: .music,
        bitrate: 128_000,
        complexity: 10,
        fec: false,
        dtx: false,
        expectedPacketLossPercent: 0
    )

    public init(
        application: Application = .music,
        bitrate: Int = 128_000,
        complexity: Int = 10,
        fec: Bool = false,
        dtx: Bool = false,
        expectedPacketLossPercent: Int = 0
    ) throws(AudioError) {
        guard complexity >= 0 && complexity <= 10 else {
            throw AudioError.invalidConfiguration(
                "complexity must be between 0 and 10, got \(complexity)"
            )
        }
        guard expectedPacketLossPercent >= 0 && expectedPacketLossPercent <= 100 else {
            throw AudioError.invalidConfiguration(
                "expected packet loss percent must be between 0 and 100, got \(expectedPacketLossPercent)"
            )
        }
        guard (bitrate >= 500 && bitrate <= 512_000) || bitrate == -1 else {
            throw AudioError.invalidConfiguration(
                "bitrate must be between 500 and 512000 or -1 (auto), got \(bitrate)"
            )
        }

        self.application = application
        self.bitrate = bitrate
        self.complexity = complexity
        self.fec = fec
        self.dtx = dtx
        self.expectedPacketLossPercent = expectedPacketLossPercent
    }

    private init(
        uncheckedApplication: Application,
        bitrate: Int,
        complexity: Int,
        fec: Bool,
        dtx: Bool,
        expectedPacketLossPercent: Int
    ) {
        self.application = uncheckedApplication
        self.bitrate = bitrate
        self.complexity = complexity
        self.fec = fec
        self.dtx = dtx
        self.expectedPacketLossPercent = expectedPacketLossPercent
    }
}
