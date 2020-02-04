@testable import HAR
import XCTest

final class BrowserTests: XCTestCase {
    func testCustomStringConvertible() {
        XCTAssertEqual(
            String(describing: HAR.Browser(name: "Firefox", version: "72.0.1")),
            "Firefox/72.0.1")
    }

    func testCustomDebugStringConvertible() {
        XCTAssertEqual(
            String(reflecting: HAR.Browser(name: "Firefox", version: "72.0.1")),
            "HAR.Browser { Firefox/72.0.1 }")
    }
}
