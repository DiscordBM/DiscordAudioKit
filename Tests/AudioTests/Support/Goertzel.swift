import Foundation

enum Goertzel {

    // computes the power of a specific target frequency in an audio buffer
    static func power(
        samples: [Float],
        sampleRate: Double,
        targetFrequency: Double
    ) -> Double {
        guard !samples.isEmpty, sampleRate > 0 else {
            return 0.0
        }

        let n = samples.count
        let k = Int(0.5 + (Double(n) * targetFrequency / sampleRate))
        let omega = (2.0 * Double.pi / Double(n)) * Double(k)
        let cosine = cos(omega)
        let coeff = 2.0 * cosine

        var sPrev: Double = 0.0
        var sPrev2: Double = 0.0

        for sample in samples {
            let s = Double(sample) + coeff * sPrev - sPrev2
            sPrev2 = sPrev
            sPrev = s
        }

        let power = sPrev2 * sPrev2 + sPrev * sPrev - coeff * sPrev * sPrev2
        return power / Double(n)
    }

    // computes power on a specific channel of an interleaved signal
    static func power(
        interleavedSamples: [Float],
        channels: Int,
        channel: Int = 0,
        sampleRate: Double,
        targetFrequency: Double
    ) -> Double {
        guard channels > 0, channel >= 0, channel < channels else {
            return 0.0
        }
        var singleChannel = [Float]()
        singleChannel.reserveCapacity(interleavedSamples.count / channels)
        for i in stride(from: channel, to: interleavedSamples.count, by: channels) {
            singleChannel.append(interleavedSamples[i])
        }
        return power(
            samples: singleChannel,
            sampleRate: sampleRate,
            targetFrequency: targetFrequency
        )
    }
}
