import Audio
import Foundation

let sampleRate = AudioConstants.sampleRate
let channels = AudioConstants.channelCount
let totalFrames = sampleRate

var samples = [Float]()
samples.reserveCapacity(totalFrames * channels)
for frame in 0..<totalFrames {
    let t = Float(frame) / Float(sampleRate)
    let s = sin(2.0 * Float.pi * 440.0 * t) * 0.5
    samples.append(s)
    samples.append(s)
}

let input: AudioInput
if CommandLine.arguments.count > 1 {
    input = .file(CommandLine.arguments[1])
} else {
    var wav = [UInt8]()
    let dataSize = samples.count * 2
    wav.append(contentsOf: "RIFF".utf8)
    withUnsafeBytes(of: UInt32(36 + dataSize).littleEndian) { wav.append(contentsOf: $0) }
    wav.append(contentsOf: "WAVEfmt ".utf8)
    withUnsafeBytes(of: UInt32(16).littleEndian) { wav.append(contentsOf: $0) }
    withUnsafeBytes(of: UInt16(1).littleEndian) { wav.append(contentsOf: $0) }
    withUnsafeBytes(of: UInt16(channels).littleEndian) { wav.append(contentsOf: $0) }
    withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { wav.append(contentsOf: $0) }
    withUnsafeBytes(of: UInt32(sampleRate * channels * 2).littleEndian) {
        wav.append(contentsOf: $0)
    }
    withUnsafeBytes(of: UInt16(channels * 2).littleEndian) { wav.append(contentsOf: $0) }
    withUnsafeBytes(of: UInt16(16).littleEndian) { wav.append(contentsOf: $0) }
    wav.append(contentsOf: "data".utf8)
    withUnsafeBytes(of: UInt32(dataSize).littleEndian) { wav.append(contentsOf: $0) }
    for sample in samples {
        let clamped = max(-1.0, min(1.0, sample))
        let intVal = Int16(clamped * 32767.0)
        withUnsafeBytes(of: intVal.littleEndian) { wav.append(contentsOf: $0) }
    }
    input = .memory(wav)
}

let decoder = try AudioDecoder(input: input)
let stream = try OpusPacketStream(decoder, configuration: .music)

var packetCount = 0
for try await packet in stream {
    assert(packet.channels == 2)
    assert(packet.durationMilliseconds == 20.0)
    assert(!packet.bytes.isEmpty)
    packetCount += 1
}

assert(packetCount > 0)
