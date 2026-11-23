import Foundation
import Testing

@testable import Audio

@Suite("Resample and Channel Conversion")
struct ResampleTests {

    @Test
    func resampleFrom44100To48000() throws {
        let path = FixtureLoader.path(named: "sine440_44100.wav")
        let decoder = try AudioDecoder(path: path, outputSampleRate: 48000, outputChannels: 2)

        #expect(decoder.info.sourceSampleRate == 44100)
        #expect(decoder.outputSampleRate == 48000)

        var allSamples = [Float]()
        while true {
            let chunk = try decoder.read(frames: 960)
            if chunk.isEmpty { break }
            allSamples.append(contentsOf: chunk)
        }

        #expect(!allSamples.isEmpty)

        // verify the 440 hz frequency is preserved accurately after resampling
        let power440 = Goertzel.power(
            interleavedSamples: allSamples,
            channels: 2,
            sampleRate: 48000,
            targetFrequency: 440.0
        )
        let power1000 = Goertzel.power(
            interleavedSamples: allSamples,
            channels: 2,
            sampleRate: 48000,
            targetFrequency: 1000.0
        )
        #expect(power440 > 0.05)
        #expect(power440 > power1000 * 100.0)
    }

    @Test
    func monoSourceUpmixesToIdenticalStereoChannels() throws {
        let path = FixtureLoader.path(named: "sine440_mono.wav")
        let decoder = try AudioDecoder(path: path, outputSampleRate: 48000, outputChannels: 2)

        #expect(decoder.info.sourceChannels == 1)
        #expect(decoder.outputChannels == 2)

        let chunk = try decoder.read(frames: 960)
        #expect(chunk.count == 1920)

        // left and right channels should be identical
        for i in 0..<960 {
            let left = chunk[2 * i]
            let right = chunk[2 * i + 1]
            #expect(left == right)
        }
    }
}
