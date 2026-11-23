import Foundation

enum WavBuilder {

    // builds valid pcm wav file bytes in memory
    static func build(
        sampleRate: Int = 48000,
        channels: Int = 2,
        bitsPerSample: Int = 16,
        samples: [Float]
    ) -> [UInt8] {
        let bytesPerSample = bitsPerSample / 8
        let blockAlign = channels * bytesPerSample
        let byteRate = sampleRate * blockAlign
        let dataSize = samples.count * bytesPerSample
        let riffChunkSize = 36 + dataSize

        var bytes = [UInt8]()
        bytes.reserveCapacity(44 + dataSize)

        // RIFF header
        bytes.append(contentsOf: "RIFF".utf8)
        withUnsafeBytes(of: UInt32(riffChunkSize).littleEndian) { bytes.append(contentsOf: $0) }
        bytes.append(contentsOf: "WAVE".utf8)

        // fmt chunk
        bytes.append(contentsOf: "fmt ".utf8)
        let fmtSize: UInt32 = 16
        withUnsafeBytes(of: fmtSize.littleEndian) { bytes.append(contentsOf: $0) }
        let formatTag: UInt16 = 1  // PCM
        withUnsafeBytes(of: formatTag.littleEndian) { bytes.append(contentsOf: $0) }
        withUnsafeBytes(of: UInt16(channels).littleEndian) { bytes.append(contentsOf: $0) }
        withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { bytes.append(contentsOf: $0) }
        withUnsafeBytes(of: UInt32(byteRate).littleEndian) { bytes.append(contentsOf: $0) }
        withUnsafeBytes(of: UInt16(blockAlign).littleEndian) { bytes.append(contentsOf: $0) }
        withUnsafeBytes(of: UInt16(bitsPerSample).littleEndian) { bytes.append(contentsOf: $0) }

        // data chunk
        bytes.append(contentsOf: "data".utf8)
        withUnsafeBytes(of: UInt32(dataSize).littleEndian) { bytes.append(contentsOf: $0) }

        if bitsPerSample == 16 {
            for sample in samples {
                let clamped = max(-1.0, min(1.0, sample))
                let intVal = Int16(clamped * 32767.0)
                withUnsafeBytes(of: intVal.littleEndian) { bytes.append(contentsOf: $0) }
            }
        }

        return bytes
    }

    // convenience for sine tone wav
    static func buildSine(
        frequency: Double = 440.0,
        sampleRate: Int = 48000,
        frames: Int = 960,
        channels: Int = 2
    ) -> [UInt8] {
        let pcm = SineWave.generate(
            frequency: frequency,
            sampleRate: sampleRate,
            frames: frames,
            channels: channels
        )
        return build(
            sampleRate: sampleRate,
            channels: channels,
            bitsPerSample: 16,
            samples: pcm
        )
    }
}
