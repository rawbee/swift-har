@testable import HAR
import XCTest

final class PagesTests: XCTestCase {
    let epoch = Date(timeIntervalSince1970: 0)

    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyyy, h:mm:ss a"
        return formatter
    }()

    func testCustomStringConvertible() {
        let page = HAR.Page(startedDateTime: epoch, id: "page_0", title: "Title", pageTimings: HAR.PageTiming(onLoad: 245))

        XCTAssertEqual(
            String(describing: page),
            "245.0ms  \(dateFormatter.string(from: epoch))  Title"
        )
    }

    func testCustomDebugStringConvertible() {
        let page = HAR.Page(startedDateTime: epoch, id: "page_0", title: "Title", pageTimings: HAR.PageTiming(onLoad: 245))

        XCTAssertEqual(
            String(reflecting: page),
            "HAR.Page { 245.0ms  \(dateFormatter.string(from: epoch))  Title }"
        )
    }
}
