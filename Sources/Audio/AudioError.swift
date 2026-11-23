public enum AudioError: Error, Equatable, Sendable, CustomStringConvertible {
    case unsupportedFormat(String)
    case invalidInput(String)
    case invalidConfiguration(String)
    case decodingFailed(Int32)
    case opusFailed(Int32)
    case endOfStream
    case closed

    public var description: String {
        switch self {
        case .unsupportedFormat(let message):
            return "unsupported audio format: \(message)"
        case .invalidInput(let message):
            return "invalid input: \(message)"
        case .invalidConfiguration(let message):
            return "invalid configuration: \(message)"
        case .decodingFailed(let code):
            return "decoding failed with error code \(code)"
        case .opusFailed(let code):
            return "opus operation failed with error code \(code)"
        case .endOfStream:
            return "end of audio stream reached"
        case .closed:
            return "audio object is closed"
        }
    }
}
