public enum SeekOrigin: Sendable, Equatable {
    case start
    case current
}

public enum AudioInput: Sendable {
    case file(String)
    case memory([UInt8])
    case stream(
        read: @Sendable (Int) throws -> [UInt8],
        seek: (@Sendable (Int64, SeekOrigin) throws -> Void)? = nil
    )
}
