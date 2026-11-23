enum Checked {

    static func int32<T: BinaryInteger>(_ value: T) throws(AudioError) -> Int32 {
        guard let result = Int32(exactly: value) else {
            throw AudioError.invalidInput("integer value \(value) exceeds Int32 range")
        }
        return result
    }

    static func int<T: BinaryInteger>(_ value: T) throws(AudioError) -> Int {
        guard let result = Int(exactly: value) else {
            throw AudioError.invalidInput("integer value \(value) exceeds Int range")
        }
        return result
    }

    static func sampleCount(frames: Int, channels: Int) throws(AudioError) -> Int {
        let (total, overflow) = frames.multipliedReportingOverflow(by: channels)
        guard !overflow, total >= 0 else {
            throw AudioError.invalidInput(
                "sample count calculation overflowed: frames=\(frames), channels=\(channels)"
            )
        }
        return total
    }
}
