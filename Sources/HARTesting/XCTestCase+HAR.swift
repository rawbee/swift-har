import HAR
import XCTest

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension XCTestCase {
    public func recordNetworkingAttachment() -> URLSession {
        addTeardownBlock { self.add(HAR.TraceURLProtocol.tearDown().attachment) }
        return HAR.TraceURLProtocol.setUp()
    }
}
