import COpus

public final class OpusDecoder {

    private let handle: NativeHandle<OpaquePointer>
    public let channels: Int

    // preallocated output buffer for maximum 120 ms frame capacity
    private var outputBuffer: [Float]

    public init(channels: Int = AudioConstants.channelCount) throws(AudioError) {
        guard channels == 1 || channels == 2 else {
            throw AudioError.invalidConfiguration(
                "opus decoder channel count must be 1 (mono) or 2 (stereo), got \(channels)"
            )
        }

        var error: Int32 = 0
        guard
            let ptr = opus_decoder_create(
                Int32(AudioConstants.sampleRate),
                Int32(channels),
                &error
            ), error == OPUS_OK
        else {
            throw AudioError.opusFailed(error)
        }

        self.handle = NativeHandle(ptr) { rawPointer in
            opus_decoder_destroy(rawPointer)
        }
        self.channels = channels
        let maxSamples = AudioConstants.maxFrameSizePerChannel * channels
        self.outputBuffer = [Float](repeating: 0.0, count: maxSamples)
    }

    public var isClosed: Bool {
        handle.isClosed
    }

    public func close() {
        handle.close()
    }

    public func decode(packet: OpusPacket) throws(AudioError) -> [Float] {
        try decode(bytes: packet.bytes)
    }

    public func decode(bytes: [UInt8]) throws(AudioError) -> [Float] {
        guard !bytes.isEmpty else {
            throw AudioError.invalidInput("opus packet payload is empty")
        }

        return try handle.withUnsafePointer { ptr in
            let samplesDecoded = try bytes.withUnsafeBufferPointer { byteBuffer in
                try outputBuffer.withUnsafeMutableBufferPointer { outBuffer in
                    guard let byteBase = byteBuffer.baseAddress else {
                        throw AudioError.invalidInput("packet byte buffer is empty")
                    }
                    guard let outBase = outBuffer.baseAddress else {
                        throw AudioError.invalidInput("output buffer is unallocated")
                    }
                    return opus_decode_float(
                        ptr,
                        byteBase,
                        Int32(byteBuffer.count),
                        outBase,
                        Int32(AudioConstants.maxFrameSizePerChannel),
                        0
                    )
                }
            }

            guard samplesDecoded > 0 else {
                throw AudioError.opusFailed(samplesDecoded)
            }

            let totalSamples = Int(samplesDecoded) * channels
            return Array(outputBuffer.prefix(totalSamples))
        }
    }

    public func decodeLoss(
        frames: Int = AudioConstants.samplesPerChannelPerFrame
    ) throws(AudioError) -> [Float] {
        guard frames > 0 && frames <= AudioConstants.maxFrameSizePerChannel else {
            throw AudioError.invalidInput(
                "loss concealment frame count must be between 1 and \(AudioConstants.maxFrameSizePerChannel), got \(frames)"
            )
        }

        return try handle.withUnsafePointer { ptr in
            let samplesDecoded = try outputBuffer.withUnsafeMutableBufferPointer { outBuffer in
                guard let outBase = outBuffer.baseAddress else {
                    throw AudioError.invalidInput("output buffer is unallocated")
                }
                return opus_decode_float(
                    ptr,
                    nil,
                    0,
                    outBase,
                    Int32(frames),
                    0
                )
            }

            guard samplesDecoded > 0 else {
                throw AudioError.opusFailed(samplesDecoded)
            }

            let totalSamples = Int(samplesDecoded) * channels
            return Array(outputBuffer.prefix(totalSamples))
        }
    }
}
