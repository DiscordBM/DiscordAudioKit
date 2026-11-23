public struct AudioFileInfo: Sendable, Equatable {

    public let sourceSampleRate: Int
    public let sourceChannels: Int
    public let lengthInFrames: Int?
    public let durationSeconds: Double?

    public init(
        sourceSampleRate: Int,
        sourceChannels: Int,
        lengthInFrames: Int?,
        durationSeconds: Double? = nil
    ) {
        self.sourceSampleRate = sourceSampleRate
        self.sourceChannels = sourceChannels
        self.lengthInFrames = lengthInFrames
        if let durationSeconds {
            self.durationSeconds = durationSeconds
        } else if let lengthInFrames, sourceSampleRate > 0 {
            self.durationSeconds = Double(lengthInFrames) / Double(sourceSampleRate)
        } else {
            self.durationSeconds = nil
        }
    }
}
