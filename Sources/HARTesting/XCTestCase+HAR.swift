import HAR
import XCTest

extension XCTestCase {
    public func recordNetworkingAttachment() -> URLSession {
        addTeardownBlock { self.add(HAR.TraceURLProtocol.tearDown().attachment) }
        return HAR.TraceURLProtocol.setUp()
    }
}
