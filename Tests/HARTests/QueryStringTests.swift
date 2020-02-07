@testable import HAR
import XCTest

final class QueryStringTests: XCTestCase {
    func testCustomStringConvertible() {
        XCTAssertEqual(
            String(describing: HAR.QueryString(name: "foo", value: "1")),
            "foo=1")
    }

    func testCustomDebugStringConvertible() {
        XCTAssertEqual(
            String(reflecting: HAR.QueryString(name: "foo", value: "1")),
            "HAR.QueryString { foo=1 }")
    }

    func testInitFromURLQueryItem() throws {
        let queryComponents = try XCTUnwrap(URLComponents(string: "http://example.com/?foo=bar&query=%40swift&message=hello+world"))
        XCTAssertEqual(queryComponents.query, "foo=bar&query=@swift&message=hello+world")
        XCTAssertEqual(
            queryComponents.queryItems,
            [
                URLQueryItem(name: "foo", value: "bar"),
                URLQueryItem(name: "query", value: "@swift"),
                URLQueryItem(name: "message", value: "hello+world"),
            ])

        XCTAssertEqual(
            queryComponents.queryItems?.map { HAR.QueryString($0) },
            [
                HAR.QueryString(name: "foo", value: "bar"),
                HAR.QueryString(name: "query", value: "@swift"),
                HAR.QueryString(name: "message", value: "hello world"),
            ])
    }
}
