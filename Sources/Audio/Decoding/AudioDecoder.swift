import CMiniaudio
import Foundation

public final class AudioDecoder {

    // ma_decoder must stay where it was initialised, so it lives on the heap
    private let decoderPtr: UnsafeMutablePointer<ma_decoder>
    private var callbackContext: DecoderCallbacks?
    private var callbackUnmanaged: Unmanaged<DecoderCallbacks>?
    private var inMemoryData: [UInt8]?
    public let outputSampleRate: Int
    public let outputChannels: Int
    public let info: AudioFileInfo
    private var isClosedState: Bool = false

    public convenience init(
        path: String,
        outputSampleRate: Int = AudioConstants.sampleRate,
        outputChannels: Int = AudioConstants.channelCount
    ) throws(AudioError) {
        try self.init(
            input: .file(path),
            outputSampleRate: outputSampleRate,
            outputChannels: outputChannels
        )
    }

    public convenience init(
        bytes: [UInt8],
        outputSampleRate: Int = AudioConstants.sampleRate,
        outputChannels: Int = AudioConstants.channelCount
    ) throws(AudioError) {
        try self.init(
            input: .memory(bytes),
            outputSampleRate: outputSampleRate,
            outputChannels: outputChannels
        )
    }

    public init(
        input: AudioInput,
        outputSampleRate: Int = AudioConstants.sampleRate,
        outputChannels: Int = AudioConstants.channelCount
    ) throws(AudioError) {
        guard outputSampleRate > 0 else {
            throw AudioError.invalidConfiguration(
                "output sample rate must be positive, got \(outputSampleRate)"
            )
        }
        guard outputChannels == 1 || outputChannels == 2 else {
            throw AudioError.invalidConfiguration(
                "output channels must be 1 (mono) or 2 (stereo), got \(outputChannels)"
            )
        }

        self.outputSampleRate = outputSampleRate
        self.outputChannels = outputChannels
        let localDecoderPtr = UnsafeMutablePointer<ma_decoder>.allocate(capacity: 1)
        self.decoderPtr = localDecoderPtr

        var config = ma_decoder_config_init(
            ma_format_f32,
            ma_uint32(outputChannels),
            ma_uint32(outputSampleRate)
        )

        switch input {
        case .file(let path):
            guard FileManager.default.fileExists(atPath: path) else {
                localDecoderPtr.deallocate()
                throw AudioError.invalidInput("file does not exist at path: \(path)")
            }
            let result = ma_decoder_init_file(path, &config, localDecoderPtr)
            guard result == MA_SUCCESS else {
                localDecoderPtr.deallocate()
                throw AudioError.decodingFailed(Int32(result.rawValue))
            }

        case .memory(let bytes):
            guard !bytes.isEmpty else {
                localDecoderPtr.deallocate()
                throw AudioError.invalidInput("input audio data is empty")
            }
            self.inMemoryData = bytes
            let result = bytes.withUnsafeBytes { rawBuffer in
                ma_decoder_init_memory(
                    rawBuffer.baseAddress,
                    rawBuffer.count,
                    &config,
                    localDecoderPtr
                )
            }

            guard result == MA_SUCCESS else {
                localDecoderPtr.deallocate()
                throw AudioError.decodingFailed(Int32(result.rawValue))
            }

        case .stream(let read, let seek):
            let callbacks = DecoderCallbacks(read: read, seek: seek)
            self.callbackContext = callbacks
            let unmanaged = Unmanaged.passRetained(callbacks)
            self.callbackUnmanaged = unmanaged

            let result = ma_decoder_init(
                miniaudioReadCallback,
                miniaudioSeekCallback,
                unmanaged.toOpaque(),
                &config,
                localDecoderPtr
            )

            if let err = callbacks.lastError {
                unmanaged.release()
                self.callbackUnmanaged = nil
                localDecoderPtr.deallocate()
                guard let audioErr = err as? AudioError else {
                    throw AudioError.invalidInput(err.localizedDescription)
                }
                throw audioErr
            }

            guard result == MA_SUCCESS else {
                unmanaged.release()
                self.callbackUnmanaged = nil
                self.callbackContext = nil
                localDecoderPtr.deallocate()
                throw AudioError.decodingFailed(Int32(result.rawValue))
            }
        }

        let srcRate = Int(decoderPtr.pointee.converter.sampleRateIn)
        let srcChannels = Int(decoderPtr.pointee.converter.channelsIn)
        let safeRate = srcRate > 0 ? srcRate : outputSampleRate
        let safeChannels = srcChannels > 0 ? srcChannels : outputChannels
        var totalFrames: ma_uint64 = 0
        let lenResult = ma_decoder_get_length_in_pcm_frames(decoderPtr, &totalFrames)
        let lengthInFrames: Int? =
            (lenResult == MA_SUCCESS && totalFrames > 0) ? Int(totalFrames) : nil

        self.info = AudioFileInfo(
            sourceSampleRate: safeRate,
            sourceChannels: safeChannels,
            lengthInFrames: lengthInFrames
        )
    }

    deinit {
        close()
    }

    public var isClosed: Bool {
        isClosedState
    }

    public func close() {
        guard !isClosedState else { return }
        isClosedState = true
        _ = ma_decoder_uninit(decoderPtr)
        decoderPtr.deallocate()
        if let unmanaged = callbackUnmanaged {
            unmanaged.release()
            callbackUnmanaged = nil
        }
        callbackContext = nil
        inMemoryData = nil
    }

    public func read(frames: Int) throws(AudioError) -> [Float] {
        guard !isClosedState else {
            throw AudioError.closed
        }
        guard frames > 0 else {
            return []
        }

        var buffer = [Float](repeating: 0.0, count: frames * outputChannels)
        var framesRead: ma_uint64 = 0

        let result = buffer.withUnsafeMutableBufferPointer { ptr in
            ma_decoder_read_pcm_frames(
                decoderPtr,
                ptr.baseAddress,
                ma_uint64(frames),
                &framesRead
            )
        }

        if let err = callbackContext?.lastError {
            callbackContext?.lastError = nil
            guard let audioErr = err as? AudioError else {
                throw AudioError.invalidInput(err.localizedDescription)
            }
            throw audioErr
        }

        guard result == MA_SUCCESS || result == MA_AT_END else {
            throw AudioError.decodingFailed(Int32(result.rawValue))
        }

        let actualSamples = Int(framesRead) * outputChannels
        if actualSamples == 0 {
            return []
        }
        return Array(buffer.prefix(actualSamples))
    }

    public func seek(toFrame frameIndex: Int) throws(AudioError) {
        guard !isClosedState else {
            throw AudioError.closed
        }
        if let callbacks = callbackContext, !callbacks.canSeek {
            throw AudioError.invalidInput("audio stream does not support seeking")
        }
        guard frameIndex >= 0 else {
            throw AudioError.invalidInput(
                "seek frame index cannot be negative: \(frameIndex)"
            )
        }

        let result = ma_decoder_seek_to_pcm_frame(decoderPtr, ma_uint64(frameIndex))

        if let err = callbackContext?.lastError {
            callbackContext?.lastError = nil
            guard let audioErr = err as? AudioError else {
                throw AudioError.invalidInput(err.localizedDescription)
            }
            throw audioErr
        }

        guard result == MA_SUCCESS else {
            throw AudioError.decodingFailed(Int32(result.rawValue))
        }
    }
}
