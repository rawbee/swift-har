@testable import HAR
import XCTest

final class HeadersTests: XCTestCase {
    func testCustomStringConvertible() {
        XCTAssertEqual(
            String(describing: HAR.Header(name: "Content-Type", value: "text/plain")),
            "Content-Type: text/plain")
    }

    func testCustomDebugStringConvertible() {
        XCTAssertEqual(
            String(reflecting: HAR.Header(name: "Content-Type", value: "text/plain")),
            "HAR.Header { Content-Type: text/plain }")
    }
}
