import struct Foundation.Data
import class Foundation.InputStream

extension Data {
    init(reading inputStream: InputStream, chunkSize: Int = 1024) throws {
        inputStream.open()
        defer { inputStream.close() }

        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: chunkSize)
        defer { buffer.deallocate() }

        self.init()

        while inputStream.hasBytesAvailable {
            let count = inputStream.read(buffer, maxLength: chunkSize)

            guard count > 0 else {
                if let error = inputStream.streamError {
                    throw error
                }
                break
            }

            append(buffer, count: count)
        }
    }
}
