import HAR
import XCTest

final class TimingsTests: XCTestCase {
    func testTotal() throws {
        let timing = HAR.Timing(
            blocked: 0, dns: -1, connect: 15, send: 20, wait: 38, receive: 12, ssl: -1
        )
        XCTAssertEqual(timing.total, 85)
    }

    func testCustomDebugStringConvertible() {
        let timing = HAR.Timing(blocked: 0, dns: 0, connect: 0, send: 0, wait: 234, receive: 47, ssl: 0)

        XCTAssertEqual(
            String(reflecting: timing),
            """
            HAR.Timing {
                Blocked: 0.0ms
                DNS: 0.0ms
                SSL/TLS: 0.0ms
                Connect: 0.0ms
                Send: 0.0ms
                Wait: 234.0ms
                Receive: 47.0ms
            }
            """
        )
    }
}
