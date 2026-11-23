import COpus

public final class OpusEncoder {

    private let handle: NativeHandle<OpaquePointer>
    public let channels: Int
    public private(set) var configuration: OpusConfiguration

    // preallocated buffer for encoded frame payload
    private var outputBuffer: [UInt8]

    public init(
        channels: Int = AudioConstants.channelCount,
        configuration: OpusConfiguration = .music
    ) throws(AudioError) {
        guard channels == 1 || channels == 2 else {
            throw AudioError.invalidConfiguration(
                "opus channel count must be 1 (mono) or 2 (stereo), got \(channels)"
            )
        }

        var error: Int32 = 0
        guard
            let ptr = opus_encoder_create(
                Int32(AudioConstants.sampleRate),
                Int32(channels),
                configuration.application.rawValue,
                &error
            ), error == OPUS_OK
        else {
            throw AudioError.opusFailed(error)
        }

        self.handle = NativeHandle(ptr) { rawPointer in
            opus_encoder_destroy(rawPointer)
        }
        self.channels = channels
        self.configuration = configuration
        self.outputBuffer = [UInt8](repeating: 0, count: 4000)

        try applyConfiguration(configuration)
    }

    public var isClosed: Bool {
        handle.isClosed
    }

    public func close() {
        handle.close()
    }

    public var lookahead: Int {
        get throws(AudioError) {
            try handle.withUnsafePointer { ptr in
                var lookaheadSamples: Int32 = 0
                let status = opus_encoder_get_ctl_int(
                    ptr,
                    OPUS_GET_LOOKAHEAD_REQUEST,
                    &lookaheadSamples
                )
                guard status == OPUS_OK else {
                    throw AudioError.opusFailed(status)
                }
                return Int(lookaheadSamples)
            }
        }
    }

    public func reconfigure(_ newConfig: OpusConfiguration) throws(AudioError) {
        try applyConfiguration(newConfig)
        self.configuration = newConfig
    }

    public func encode(frame: [Float]) throws(AudioError) -> OpusPacket {
        let expectedSamples = channels * AudioConstants.samplesPerChannelPerFrame
        guard frame.count == expectedSamples else {
            throw AudioError.invalidInput(
                "input frame sample count must be \(expectedSamples) for \(channels) channels, got \(frame.count)"
            )
        }

        return try handle.withUnsafePointer { ptr in
            let bytesWritten = try frame.withUnsafeBufferPointer { pcmBuffer in
                try outputBuffer.withUnsafeMutableBufferPointer { outBuffer in
                    guard let pcmBase = pcmBuffer.baseAddress else {
                        throw AudioError.invalidInput("pcm frame buffer is empty")
                    }
                    guard let outBase = outBuffer.baseAddress else {
                        throw AudioError.invalidInput("output buffer is unallocated")
                    }
                    return opus_encode_float(
                        ptr,
                        pcmBase,
                        Int32(AudioConstants.samplesPerChannelPerFrame),
                        outBase,
                        Int32(outBuffer.count)
                    )
                }
            }

            guard bytesWritten > 0 else {
                throw AudioError.opusFailed(bytesWritten)
            }

            let slice = outputBuffer.prefix(Int(bytesWritten))
            return try OpusPacket(bytes: Array(slice))
        }
    }

    private func applyConfiguration(_ config: OpusConfiguration) throws(AudioError) {
        try handle.withUnsafePointer { ptr in
            var status = opus_encoder_set_ctl_int(
                ptr,
                OPUS_SET_BITRATE_REQUEST,
                Int32(config.bitrate)
            )
            guard status == OPUS_OK else { throw AudioError.opusFailed(status) }

            status = opus_encoder_set_ctl_int(
                ptr,
                OPUS_SET_COMPLEXITY_REQUEST,
                Int32(config.complexity)
            )
            guard status == OPUS_OK else { throw AudioError.opusFailed(status) }

            status = opus_encoder_set_ctl_int(
                ptr,
                OPUS_SET_INBAND_FEC_REQUEST,
                Int32(config.fec ? 1 : 0)
            )
            guard status == OPUS_OK else { throw AudioError.opusFailed(status) }

            status = opus_encoder_set_ctl_int(
                ptr,
                OPUS_SET_DTX_REQUEST,
                Int32(config.dtx ? 1 : 0)
            )
            guard status == OPUS_OK else { throw AudioError.opusFailed(status) }

            status = opus_encoder_set_ctl_int(
                ptr,
                OPUS_SET_PACKET_LOSS_PERC_REQUEST,
                Int32(config.expectedPacketLossPercent)
            )
            guard status == OPUS_OK else { throw AudioError.opusFailed(status) }
        }
    }
}
