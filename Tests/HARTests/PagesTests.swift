@testable import HAR
import XCTest

final class PagesTests: XCTestCase {
    let epoch = Date(timeIntervalSince1970: 0)

    func testCustomStringConvertible() {
        XCTAssertEqual(
            String(describing: HAR.Page(startedDateTime: epoch, id: "page_0", title: "Title")),
            "1970-01-01 00:00:00 +0000: page_0 \"Title\" - onContentLoad: -1.0, onLoad: -1.0")
    }

    func testCustomDebugStringConvertible() {
        XCTAssertEqual(
            String(reflecting: HAR.Page(startedDateTime: epoch, id: "page_0", title: "Title")),
            "HAR.Page { 1970-01-01 00:00:00 +0000: page_0 \"Title\" - onContentLoad: -1.0, onLoad: -1.0 }")
    }
}
