@testable import HAR
import XCTest

final class PageTimingsTests: XCTestCase {
    func testCustomStringConvertible() {
        XCTAssertEqual(
            String(describing: HAR.PageTiming()),
            "onContentLoad: -1.0, onLoad: -1.0")
        XCTAssertEqual(
            String(describing: HAR.PageTiming(onContentLoad: 1720, onLoad: 2500)),
            "onContentLoad: 1720.0, onLoad: 2500.0")
    }

    func testCustomDebugStringConvertible() {
        XCTAssertEqual(
            String(reflecting: HAR.PageTiming()),
            "HAR.PageTiming { onContentLoad: -1.0, onLoad: -1.0 }")
        XCTAssertEqual(
            String(reflecting: HAR.PageTiming(onContentLoad: 1720, onLoad: 2500)),
            "HAR.PageTiming { onContentLoad: 1720.0, onLoad: 2500.0 }")
    }
}
