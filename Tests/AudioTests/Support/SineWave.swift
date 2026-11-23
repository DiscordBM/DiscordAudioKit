import Foundation

enum SineWave {

    // generates interleaved float samples for a pure sine tone
    static func generate(
        frequency: Double = 440.0,
        sampleRate: Int = 48000,
        frames: Int = 960,
        channels: Int = 2,
        amplitude: Float = 0.5
    ) -> [Float] {
        var samples = [Float]()
        samples.reserveCapacity(frames * channels)

        let twoPi = 2.0 * Double.pi
        for frame in 0..<frames {
            let t = Double(frame) / Double(sampleRate)
            let val = amplitude * Float(sin(twoPi * frequency * t))
            for _ in 0..<channels {
                samples.append(val)
            }
        }
        return samples
    }
}
