@testable import HAR
import XCTest

final class CreatorTests: XCTestCase {
    func testCustomStringConvertible() {
        XCTAssertEqual(
            String(describing: HAR.Creator(name: "WebKit Web Inspector", version: "605.1.15")),
            "WebKit Web Inspector/605.1.15")
    }

    func testCustomDebugStringConvertible() {
        XCTAssertEqual(
            String(reflecting: HAR.Creator(name: "WebKit Web Inspector", version: "605.1.15")),
            "HAR.Browser { WebKit Web Inspector/605.1.15 }")
    }
}
