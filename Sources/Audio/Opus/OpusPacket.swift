import COpus

public struct OpusPacket: Sendable, Equatable {

    public let bytes: [UInt8]
    public let channels: Int
    public let frameCount: Int
    public let samplesPerFrame: Int

    public var totalSamples: Int {
        frameCount * samplesPerFrame
    }

    public var durationMilliseconds: Double {
        Double(totalSamples) / (Double(AudioConstants.sampleRate) / 1000.0)
    }

    // discord silence packet: 3-byte stereo 20ms frame (f8 ff fe)
    public static let silence: OpusPacket = {
        do {
            return try OpusPacket(bytes: AudioConstants.silencePacket)
        } catch {
            return OpusPacket(
                uncheckedBytes: AudioConstants.silencePacket,
                channels: AudioConstants.channelCount,
                frameCount: 1,
                samplesPerFrame: AudioConstants.samplesPerChannelPerFrame
            )
        }
    }()

    public init(bytes: [UInt8]) throws(AudioError) {
        guard !bytes.isEmpty else {
            throw AudioError.invalidInput("opus packet payload is empty")
        }
        guard bytes.count <= Int(Int32.max) else {
            throw AudioError.invalidInput("opus packet payload length exceeds Int32.max")
        }

        let ch = opus_packet_get_nb_channels(bytes)
        guard ch > 0 else {
            throw AudioError.invalidInput(
                "corrupted opus packet with invalid channel count: \(ch)"
            )
        }

        let frames = opus_packet_get_nb_frames(bytes, Int32(bytes.count))
        guard frames > 0 else {
            throw AudioError.invalidInput(
                "corrupted opus packet with invalid frame count: \(frames)"
            )
        }

        let samples = opus_packet_get_samples_per_frame(
            bytes,
            Int32(AudioConstants.sampleRate)
        )
        guard samples > 0 else {
            throw AudioError.invalidInput(
                "corrupted opus packet with invalid sample count per frame: \(samples)"
            )
        }

        self.bytes = bytes
        self.channels = Int(ch)
        self.frameCount = Int(frames)
        self.samplesPerFrame = Int(samples)
    }

    private init(
        uncheckedBytes: [UInt8],
        channels: Int,
        frameCount: Int,
        samplesPerFrame: Int
    ) {
        self.bytes = uncheckedBytes
        self.channels = channels
        self.frameCount = frameCount
        self.samplesPerFrame = samplesPerFrame
    }
}
