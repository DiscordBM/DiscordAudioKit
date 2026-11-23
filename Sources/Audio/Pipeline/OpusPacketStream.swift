public final class OpusPacketStream: AsyncSequence {
    public typealias Element = OpusPacket

    private let decoder: AudioDecoder
    private let encoder: OpusEncoder
    private var chunker: FrameChunker
    private var reachedEndOfInput: Bool = false
    private var isFinished: Bool = false
    private var isClosedState: Bool = false

    public init(
        _ decoder: AudioDecoder,
        configuration: OpusConfiguration = .music
    ) throws(AudioError) {
        let encoder = try OpusEncoder(
            channels: decoder.outputChannels,
            configuration: configuration
        )
        self.decoder = decoder
        self.encoder = encoder
        self.chunker = FrameChunker(channels: decoder.outputChannels)
    }

    public init(
        decoder: AudioDecoder,
        encoder: OpusEncoder
    ) throws(AudioError) {
        guard decoder.outputChannels == encoder.channels else {
            throw AudioError.invalidConfiguration(
                "decoder channels (\(decoder.outputChannels)) must match encoder channels (\(encoder.channels))"
            )
        }
        self.decoder = decoder
        self.encoder = encoder
        self.chunker = FrameChunker(channels: decoder.outputChannels)
    }

    public var isClosed: Bool {
        isClosedState || decoder.isClosed || encoder.isClosed
    }

    public func close() {
        guard !isClosedState else { return }
        isClosedState = true
        chunker.reset()
        decoder.close()
        encoder.close()
    }

    deinit {
        close()
    }

    public func next() throws(AudioError) -> OpusPacket? {
        guard !isClosed else {
            throw AudioError.closed
        }
        if isFinished {
            return nil
        }

        while chunker.bufferedSampleCount < chunker.frameSampleCount {
            if reachedEndOfInput {
                if let finalFrame = chunker.finish(padWithSilence: true) {
                    isFinished = true
                    return try encoder.encode(frame: finalFrame)
                }
                isFinished = true
                return nil
            }

            let samples = try decoder.read(frames: chunker.samplesPerChannel)
            if samples.isEmpty {
                reachedEndOfInput = true
            } else {
                chunker.append(samples)
            }
        }

        if let frame = chunker.nextFrame() {
            return try encoder.encode(frame: frame)
        }

        if reachedEndOfInput {
            if let finalFrame = chunker.finish(padWithSilence: true) {
                isFinished = true
                return try encoder.encode(frame: finalFrame)
            }
            isFinished = true
            return nil
        }

        return nil
    }

    public struct AsyncIterator: AsyncIteratorProtocol {
        public typealias Element = OpusPacket

        private let stream: OpusPacketStream

        fileprivate init(stream: OpusPacketStream) {
            self.stream = stream
        }

        public mutating func next() async throws -> OpusPacket? {
            if Task.isCancelled {
                stream.close()
                return nil
            }
            return try stream.next()
        }
    }

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(stream: self)
    }
}
