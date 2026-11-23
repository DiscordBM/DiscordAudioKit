import CMiniaudio
import Foundation

// manages callback state and bridges swift closures to miniaudio function pointers
final class DecoderCallbacks {

    private let readClosure: @Sendable (Int) throws -> [UInt8]
    private let seekClosure: (@Sendable (Int64, SeekOrigin) throws -> Void)?
    var lastError: (any Error)?
    var canSeek: Bool {
        seekClosure != nil
    }

    // buffer to allow miniaudio format detection and header probing on non-seekable streams
    private static let maxProbeBufferSize = 65536
    private var initialBuffer = [UInt8]()
    private var bufferCursor = 0

    init(
        read: @escaping @Sendable (Int) throws -> [UInt8],
        seek: (@Sendable (Int64, SeekOrigin) throws -> Void)? = nil
    ) {
        self.readClosure = read
        self.seekClosure = seek
        self.lastError = nil
    }

    func onRead(buffer: UnsafeMutableRawPointer, bytesToRead: Int) -> Int {
        do {
            var bytesCopied = 0

            // replay from buffered probe data if cursor is within initialBuffer
            if bufferCursor < initialBuffer.count {
                let available = initialBuffer.count - bufferCursor
                let count = min(available, bytesToRead)
                initialBuffer.withUnsafeBytes { rawBuffer in
                    if let src = rawBuffer.baseAddress {
                        buffer.copyMemory(
                            from: src.advanced(by: bufferCursor),
                            byteCount: count
                        )
                    }
                }
                bufferCursor += count
                bytesCopied += count
                if bytesCopied == bytesToRead {
                    return bytesCopied
                }
            }

            // read fresh bytes from the underlying stream
            let remaining = bytesToRead - bytesCopied
            let freshBytes = try readClosure(remaining)
            let freshCount = min(freshBytes.count, remaining)
            if freshCount > 0 {
                freshBytes.withUnsafeBytes { rawBuffer in
                    if let src = rawBuffer.baseAddress {
                        buffer.advanced(by: bytesCopied).copyMemory(
                            from: src,
                            byteCount: freshCount
                        )
                    }
                }
                bytesCopied += freshCount

                // buffer headers for format probing on non-seekable streams up to limit
                if seekClosure == nil && initialBuffer.count < Self.maxProbeBufferSize {
                    let toBuffer = min(freshCount, Self.maxProbeBufferSize - initialBuffer.count)
                    initialBuffer.append(contentsOf: freshBytes.prefix(toBuffer))
                    bufferCursor += toBuffer
                }
            }
            return bytesCopied
        } catch {
            lastError = error
            return 0
        }
    }

    func onSeek(byteOffset: Int64, origin: SeekOrigin) -> Bool {
        if let seekClosure {
            do {
                try seekClosure(byteOffset, origin)
                return true
            } catch {
                lastError = error
                return false
            }
        }

        // simulate seeking on buffered stream headers for probe autodetection
        let currentPos = Int64(bufferCursor)
        let targetPos: Int64
        switch origin {
        case .start:
            targetPos = byteOffset
        case .current:
            targetPos = currentPos + byteOffset
        }

        guard targetPos >= 0 else {
            return false
        }

        if targetPos <= Int64(initialBuffer.count) {
            bufferCursor = Int(targetPos)
            return true
        }

        // forward seek within probe buffer limit
        if initialBuffer.count < Self.maxProbeBufferSize {
            let needed = min(
                Int(targetPos) - initialBuffer.count,
                Self.maxProbeBufferSize - initialBuffer.count
            )
            if needed > 0 {
                do {
                    let bytes = try readClosure(needed)
                    initialBuffer.append(contentsOf: bytes)
                    if initialBuffer.count >= Int(targetPos) {
                        bufferCursor = Int(targetPos)
                        return true
                    }
                } catch {
                    lastError = error
                    return false
                }
            }
        }
        return false
    }
}

// c function pointer for miniaudio read callback
func miniaudioReadCallback(
    pDecoder: UnsafeMutablePointer<ma_decoder>?,
    pBufferOut: UnsafeMutableRawPointer?,
    bytesToRead: Int,
    pBytesRead: UnsafeMutablePointer<Int>?
) -> ma_result {
    guard let pDecoder, let pBufferOut else {
        return MA_INVALID_ARGS
    }
    guard let pUserData = pDecoder.pointee.pUserData else {
        return MA_INVALID_ARGS
    }
    let callbacks = Unmanaged<DecoderCallbacks>.fromOpaque(pUserData).takeUnretainedValue()
    let readCount = callbacks.onRead(buffer: pBufferOut, bytesToRead: bytesToRead)
    pBytesRead?.pointee = readCount
    if callbacks.lastError != nil {
        return MA_ERROR
    }
    return MA_SUCCESS
}

// c function pointer for miniaudio seek callback
func miniaudioSeekCallback(
    pDecoder: UnsafeMutablePointer<ma_decoder>?,
    byteOffset: Int64,
    origin: ma_seek_origin
) -> ma_result {
    guard let pDecoder else {
        return MA_INVALID_ARGS
    }
    guard let pUserData = pDecoder.pointee.pUserData else {
        return MA_INVALID_ARGS
    }
    let callbacks = Unmanaged<DecoderCallbacks>.fromOpaque(pUserData).takeUnretainedValue()
    let seekOrigin: SeekOrigin
    switch origin {
    case ma_seek_origin_start:
        seekOrigin = .start
    case ma_seek_origin_current:
        seekOrigin = .current
    default:
        return MA_NOT_IMPLEMENTED
    }
    let success = callbacks.onSeek(byteOffset: byteOffset, origin: seekOrigin)
    if callbacks.lastError != nil {
        return MA_ERROR
    }
    return success ? MA_SUCCESS : MA_NOT_IMPLEMENTED
}
