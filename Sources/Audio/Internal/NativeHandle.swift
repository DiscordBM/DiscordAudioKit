#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#endif

// raw pointer wrapper with idempotent teardown, thread-safe access
final class NativeHandle<Pointer>: @unchecked Sendable {

    private var pointer: Pointer?
    private let destroy: (Pointer) -> Void
    private var mutex = pthread_mutex_t()

    init(_ pointer: Pointer, destroy: @escaping (Pointer) -> Void) {
        self.pointer = pointer
        self.destroy = destroy
        pthread_mutex_init(&mutex, nil)
    }

    deinit {
        close()
        pthread_mutex_destroy(&mutex)
    }

    func close() {
        pthread_mutex_lock(&mutex)
        guard let p = pointer else {
            pthread_mutex_unlock(&mutex)
            return
        }
        pointer = nil
        pthread_mutex_unlock(&mutex)
        destroy(p)
    }

    var isClosed: Bool {
        pthread_mutex_lock(&mutex)
        let closed = (pointer == nil)
        pthread_mutex_unlock(&mutex)
        return closed
    }

    func withUnsafePointer<R, E: Error>(
        _ body: (Pointer) throws(E) -> R
    ) throws(AudioError) -> R {
        pthread_mutex_lock(&mutex)
        guard let p = pointer else {
            pthread_mutex_unlock(&mutex)
            throw AudioError.closed
        }
        pthread_mutex_unlock(&mutex)

        do {
            return try body(p)
        } catch let err as AudioError {
            throw err
        } catch {
            throw AudioError.invalidInput("native operation failed")
        }
    }
}
