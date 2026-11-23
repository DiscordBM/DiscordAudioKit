import CMiniaudio
import COpus
import Testing

@testable import Audio

@Suite("Audio Native Link Spike")
struct LinkTests {

    @Test
    func opusVersionStringIsNotEmpty() {
        let versionPtr = opus_get_version_string()
        #expect(versionPtr != nil)
        if let versionPtr {
            let version = String(cString: versionPtr)
            #expect(!version.isEmpty)
            #expect(version.contains("libopus"))
        }
    }

    @Test
    func tinyWavDecodesInMemoryViaMiniaudio() {
        // synthesize a tiny 48khz 16-bit mono wav in memory (480 samples = 10 ms)
        let sampleRate: UInt32 = 48000
        let channels: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        let sampleCount: UInt32 = 480
        let dataSize: UInt32 = sampleCount * UInt32(channels) * UInt32(bitsPerSample / 8)

        var wavBytes = [UInt8]()
        wavBytes.reserveCapacity(Int(44 + dataSize))

        // RIFF header
        wavBytes.append(contentsOf: "RIFF".utf8)
        let fileSize: UInt32 = 36 + dataSize
        withUnsafeBytes(of: fileSize.littleEndian) { wavBytes.append(contentsOf: $0) }
        wavBytes.append(contentsOf: "WAVE".utf8)

        // fmt chunk
        wavBytes.append(contentsOf: "fmt ".utf8)
        let fmtChunkSize: UInt32 = 16
        withUnsafeBytes(of: fmtChunkSize.littleEndian) { wavBytes.append(contentsOf: $0) }
        let formatTag: UInt16 = 1  // PCM
        withUnsafeBytes(of: formatTag.littleEndian) { wavBytes.append(contentsOf: $0) }
        withUnsafeBytes(of: channels.littleEndian) { wavBytes.append(contentsOf: $0) }
        withUnsafeBytes(of: sampleRate.littleEndian) { wavBytes.append(contentsOf: $0) }
        let byteRate: UInt32 = sampleRate * UInt32(channels) * UInt32(bitsPerSample / 8)
        withUnsafeBytes(of: byteRate.littleEndian) { wavBytes.append(contentsOf: $0) }
        let blockAlign: UInt16 = channels * (bitsPerSample / 8)
        withUnsafeBytes(of: blockAlign.littleEndian) { wavBytes.append(contentsOf: $0) }
        withUnsafeBytes(of: bitsPerSample.littleEndian) { wavBytes.append(contentsOf: $0) }

        // data chunk
        wavBytes.append(contentsOf: "data".utf8)
        withUnsafeBytes(of: dataSize.littleEndian) { wavBytes.append(contentsOf: $0) }

        // sample data (480 zero samples)
        wavBytes.append(contentsOf: [UInt8](repeating: 0, count: Int(dataSize)))

        // init miniaudio decoder in memory
        var decoder = ma_decoder()
        var config = ma_decoder_config_init(ma_format_f32, 2, 48000)

        let result = wavBytes.withUnsafeBytes { rawBuffer -> ma_result in
            guard let baseAddress = rawBuffer.baseAddress else { return MA_ERROR }
            return ma_decoder_init_memory(baseAddress, rawBuffer.count, &config, &decoder)
        }

        #expect(result == MA_SUCCESS)

        if result == MA_SUCCESS {
            var readBuffer = [Float](repeating: 0, count: 960)  // 480 frames * 2 channels
            var framesRead: ma_uint64 = 0
            let readResult = ma_decoder_read_pcm_frames(
                &decoder,
                &readBuffer,
                480,
                &framesRead
            )

            #expect(readResult == MA_SUCCESS)
            #expect(framesRead == 480)

            ma_decoder_uninit(&decoder)
        }
    }

    @Test
    func repeatedOpusEncoderCreateAndDestroyRunsClean() {
        var error: Int32 = 0
        for _ in 0..<200 {
            let encoder = opus_encoder_create(48000, 2, OPUS_APPLICATION_VOIP, &error)
            #expect(error == OPUS_OK)
            #expect(encoder != nil)
            if let encoder {
                opus_encoder_destroy(encoder)
            }
        }
    }

    @Test
    func repeatedOpusDecoderCreateAndDestroyRunsClean() {
        var error: Int32 = 0
        for _ in 0..<200 {
            let decoder = opus_decoder_create(48000, 2, &error)
            #expect(error == OPUS_OK)
            #expect(decoder != nil)
            if let decoder {
                opus_decoder_destroy(decoder)
            }
        }
    }
}
