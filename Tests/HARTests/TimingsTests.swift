@testable import HAR
import XCTest

final class TimingsTests: XCTestCase {
    func testTotal() throws {
        let timing = HAR.Timing(blocked: 0, dns: -1, connect: 15, send: 20, wait: 38, receive: 12, ssl: -1)
        XCTAssertEqual(timing.total, 85)
    }
}
