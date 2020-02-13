@testable import HAR
import XCTest

final class PagesTests: XCTestCase {
    let epoch = Date(timeIntervalSince1970: 0)

    func testCustomStringConvertible() {
        let page = HAR.Page(startedDateTime: epoch, id: "page_0", title: "Title", pageTimings: HAR.PageTiming(onLoad: 245))

        XCTAssertEqual(
            String(describing: page),
            "245.0ms  12/31/1969, 4:00:00 PM  Title"
        )
    }

    func testCustomDebugStringConvertible() {
        let page = HAR.Page(startedDateTime: epoch, id: "page_0", title: "Title", pageTimings: HAR.PageTiming(onLoad: 245))

        XCTAssertEqual(
            String(reflecting: page),
            "HAR.Page { 245.0ms  12/31/1969, 4:00:00 PM  Title }"
        )
    }
}
