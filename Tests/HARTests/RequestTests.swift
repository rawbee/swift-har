@testable import HAR
import XCTest

final class RequestTests: XCTestCase {
    func testValueForHTTPHeaderField() throws {
        let url = try XCTUnwrap(URL(string: "http://example.com"))

        var req = HAR.Request(method: "POST", url: url)
        req.headers = [
            HAR.Header(("Accept", "*/*")),
            HAR.Header(("Content-Type", "application/json")),
        ]
        XCTAssertEqual(req.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(req.value(forHTTPHeaderField: "Content-type"), "application/json")
        XCTAssertEqual(req.value(forHTTPHeaderField: "content-type"), "application/json")
        XCTAssertNil(req.value(forHTTPHeaderField: "type"))
    }
}
