public struct FrameChunker: Sendable {

    public let channels: Int
    public let samplesPerChannel: Int
    public let frameSampleCount: Int
    private var buffer: [Float]
    private var readOffset: Int

    public init(
        channels: Int = AudioConstants.channelCount,
        samplesPerChannel: Int = AudioConstants.samplesPerChannelPerFrame
    ) {
        self.channels = channels
        self.samplesPerChannel = samplesPerChannel
        self.frameSampleCount = samplesPerChannel * channels
        self.buffer = []
        self.readOffset = 0
    }

    public var bufferedSampleCount: Int {
        buffer.count - readOffset
    }

    public var isEmpty: Bool {
        bufferedSampleCount == 0
    }

    public mutating func append(_ samples: [Float]) {
        // prevent unbounded memory growth from sliding offset
        if readOffset > 4096 {
            buffer.removeFirst(readOffset)
            readOffset = 0
        }
        buffer.append(contentsOf: samples)
    }

    public mutating func nextFrame() -> [Float]? {
        guard bufferedSampleCount >= frameSampleCount else {
            return nil
        }
        let frame = Array(buffer[readOffset..<(readOffset + frameSampleCount)])
        readOffset += frameSampleCount
        if readOffset >= buffer.count {
            buffer.removeAll(keepingCapacity: true)
            readOffset = 0
        }
        return frame
    }

    public mutating func push(_ samples: [Float]) -> [[Float]] {
        append(samples)
        var frames: [[Float]] = []
        while let frame = nextFrame() {
            frames.append(frame)
        }
        return frames
    }

    public mutating func finish(padWithSilence: Bool = true) -> [Float]? {
        let remaining = bufferedSampleCount
        guard remaining > 0 else {
            reset()
            return nil
        }

        var frame = Array(buffer[readOffset..<buffer.count])
        reset()

        if padWithSilence {
            let paddingNeeded = frameSampleCount - frame.count
            if paddingNeeded > 0 {
                frame.append(contentsOf: repeatElement(0.0, count: paddingNeeded))
            }
        }
        return frame
    }

    public mutating func reset() {
        buffer.removeAll(keepingCapacity: true)
        readOffset = 0
    }
}
