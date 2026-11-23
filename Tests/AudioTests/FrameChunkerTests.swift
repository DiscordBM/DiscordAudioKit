import Testing

@testable import Audio

@Suite("FrameChunker")
struct FrameChunkerTests {

    @Test
    func inputOfAnySizeYieldsExactFrames() {
        var chunker = FrameChunker(channels: 2)
        #expect(chunker.frameSampleCount == 1920)
        #expect(chunker.isEmpty)

        let chunkSizes = [100, 350, 800, 1500, 200, 1000]
        var totalYieldedFrames: [[Float]] = []

        var sampleCounter: Float = 1.0
        for size in chunkSizes {
            var chunk: [Float] = []
            chunk.reserveCapacity(size)
            for _ in 0..<size {
                chunk.append(sampleCounter)
                sampleCounter += 1.0
            }
            let frames = chunker.push(chunk)
            totalYieldedFrames.append(contentsOf: frames)
        }

        // total samples = 3950. 3950 / 1920 = 2 full frames (3840 samples), 110 remainder
        #expect(totalYieldedFrames.count == 2)
        for frame in totalYieldedFrames {
            #expect(frame.count == 1920)
        }
        #expect(chunker.bufferedSampleCount == 110)

        // finish with silence padding yields the 3rd frame (110 original + 1810 silence)
        let finalFrame = chunker.finish(padWithSilence: true)
        #expect(finalFrame != nil)
        #expect(finalFrame?.count == 1920)
        #expect(finalFrame?[0] == 3841.0)
        #expect(finalFrame?[109] == 3950.0)
        #expect(finalFrame?[110] == 0.0)
        #expect(finalFrame?[1919] == 0.0)

        #expect(chunker.isEmpty)
        #expect(chunker.finish() == nil)
    }

    @Test
    func remainderCarriesOverSequentially() {
        var chunker = FrameChunker(channels: 2)

        let first = [Float](repeating: 1.0, count: 1000)
        let frames1 = chunker.push(first)
        #expect(frames1.isEmpty)
        #expect(chunker.bufferedSampleCount == 1000)

        let second = [Float](repeating: 2.0, count: 1000)
        let frames2 = chunker.push(second)
        #expect(frames2.count == 1)
        #expect(frames2[0].count == 1920)
        #expect(frames2[0][0] == 1.0)
        #expect(frames2[0][999] == 1.0)
        #expect(frames2[0][1000] == 2.0)
        #expect(frames2[0][1919] == 2.0)
        #expect(chunker.bufferedSampleCount == 80)

        let third = [Float](repeating: 3.0, count: 1840)
        let frames3 = chunker.push(third)
        #expect(frames3.count == 1)
        #expect(frames3[0].count == 1920)
        #expect(frames3[0][0] == 2.0)
        #expect(frames3[0][79] == 2.0)
        #expect(frames3[0][80] == 3.0)
        #expect(chunker.bufferedSampleCount == 0)
        #expect(chunker.isEmpty)

        #expect(chunker.finish() == nil)
    }

    @Test
    func lastPartialFrameIsPaddedWithSilence() {
        var chunker = FrameChunker(channels: 2)

        let samples = [Float](repeating: 0.5, count: 500)
        chunker.append(samples)
        #expect(chunker.nextFrame() == nil)

        let finalFrame = chunker.finish(padWithSilence: true)
        #expect(finalFrame != nil)
        #expect(finalFrame?.count == 1920)
        if let frame = finalFrame {
            #expect(frame[0] == 0.5)
            #expect(frame[499] == 0.5)
            #expect(frame[500] == 0.0)
            #expect(frame[1919] == 0.0)
        }
    }

    @Test
    func exactMultipleYieldsExactFramesAndEmptyFinish() {
        var chunker = FrameChunker(channels: 2)

        let samples = [Float](repeating: 0.1, count: 1920 * 3)
        let frames = chunker.push(samples)
        #expect(frames.count == 3)
        #expect(chunker.isEmpty)
        #expect(chunker.finish() == nil)
    }

    @Test
    func emptyInputYieldsNoFrames() {
        var chunker = FrameChunker(channels: 2)
        let frames = chunker.push([])
        #expect(frames.isEmpty)
        #expect(chunker.finish() == nil)
    }

    @Test
    func monoChunkerYields960Frames() {
        var chunker = FrameChunker(channels: 1)
        #expect(chunker.frameSampleCount == 960)

        let samples = [Float](repeating: 0.2, count: 1000)
        let frames = chunker.push(samples)
        #expect(frames.count == 1)
        #expect(frames[0].count == 960)
        #expect(chunker.bufferedSampleCount == 40)

        let finalFrame = chunker.finish(padWithSilence: true)
        #expect(finalFrame?.count == 960)
        #expect(finalFrame?[0] == 0.2)
        #expect(finalFrame?[39] == 0.2)
        #expect(finalFrame?[40] == 0.0)
        #expect(finalFrame?[959] == 0.0)
    }

    @Test
    func resetClearsBuffer() {
        var chunker = FrameChunker(channels: 2)
        chunker.append([Float](repeating: 0.7, count: 500))
        #expect(!chunker.isEmpty)

        chunker.reset()
        #expect(chunker.isEmpty)
        #expect(chunker.bufferedSampleCount == 0)
        #expect(chunker.finish() == nil)
    }
}
