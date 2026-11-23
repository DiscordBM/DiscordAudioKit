import Testing

@testable import Audio

@Suite("NativeHandle")
struct NativeHandleTests {

    final class DummyBox {
        var closedCount: Int = 0
    }

    @Test
    func lifecycleAndIdempotentClose() throws {
        let box = DummyBox()
        let handle = NativeHandle(box) { b in
            b.closedCount += 1
        }

        #expect(!handle.isClosed)

        let value = try handle.withUnsafePointer { b in
            b.closedCount
        }
        #expect(value == 0)

        handle.close()
        #expect(handle.isClosed)
        #expect(box.closedCount == 1)

        // second close must be a no-op
        handle.close()
        #expect(box.closedCount == 1)

        // using closed handle must throw closed
        #expect(throws: AudioError.closed) {
            try handle.withUnsafePointer { _ in }
        }
    }

    @Test
    func deinitClosesHandle() {
        let box = DummyBox()
        do {
            let handle = NativeHandle(box) { b in
                b.closedCount += 1
            }
            #expect(!handle.isClosed)
        }
        #expect(box.closedCount == 1)
    }
}
