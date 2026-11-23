import Foundation

enum Correlation {

    // finds the lag that maximizes normalized cross-correlation between two signals
    static func best(
        reference: [Float],
        signal: [Float],
        maxLag: Int = 960
    ) -> (lag: Int, score: Double) {
        guard !reference.isEmpty, !signal.isEmpty else {
            return (0, 0.0)
        }

        var bestLag = 0
        var bestScore: Double = -1.0

        let searchMax = min(maxLag, signal.count - 1)
        for lag in 0...searchMax {
            let count = min(reference.count, signal.count - lag)
            guard count > 0 else { continue }

            var dot: Double = 0.0
            var normRef: Double = 0.0
            var normSig: Double = 0.0

            for i in 0..<count {
                let r = Double(reference[i])
                let s = Double(signal[i + lag])
                dot += r * s
                normRef += r * r
                normSig += s * s
            }

            let denom = sqrt(normRef * normSig)
            if denom > 0.0 {
                let score = dot / denom
                if score > bestScore {
                    bestScore = score
                    bestLag = lag
                }
            }
        }

        return (bestLag, bestScore)
    }
}
