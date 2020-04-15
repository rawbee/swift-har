import HAR
import XCTest

extension XCTestCase {
#if !os(Linux)
    public func recordNetworkingAttachment() -> URLSession {
        addTeardownBlock { self.add(HAR.TraceURLProtocol.tearDown().attachment) }
        return HAR.TraceURLProtocol.setUp()
    }
#endif
}
