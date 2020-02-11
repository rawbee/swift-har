@testable import HAR
import XCTest

final class HeadersTests: XCTestCase {
    func testCustomStringConvertible() {
        XCTAssertEqual(
            String(describing: HAR.Header(name: "Content-Type", value: "text/plain")),
            "Content-Type: text/plain"
        )
    }

    func testCustomDebugStringConvertible() {
        XCTAssertEqual(
            String(reflecting: HAR.Header(name: "Content-Type", value: "text/plain")),
            "HAR.Header { Content-Type: text/plain }"
        )
    }

    func testHeadersAsDictionary() {
        XCTAssertEqual(
            [
                HAR.Header(name: "Accept", value: "text/html"),
                HAR.Header(name: "Content-Length", value: "348"),
                HAR.Header(name: "Cache-Control", value: "no-cache"),
                HAR.Header(name: "Cache-Control", value: "no-store"),
            ].headersAsDictionary,
            [
                "Accept": "text/html",
                "Content-Length": "348",
                "Cache-Control": "no-cache, no-store",
            ]
        )

        XCTAssertEqual(
            [
                HAR.Header(name: "Content-Type", value: "text/html"),
                HAR.Header(name: "Content-Length", value: "348"),
                HAR.Header(name: "Set-Cookie", value: "theme=light"),
                HAR.Header(name: "Set-Cookie", value: "sessionToken=abc123; Expires=Wed, 09 Jun 2021 10:18:14 GMT"),
            ].headersAsDictionary,
            [
                "Content-Type": "text/html",
                "Content-Length": "348",
                "Set-Cookie": "theme=light, sessionToken=abc123; Expires=Wed, 09 Jun 2021 10:18:14 GMT",
            ]
        )
    }

    func testHeadersFromDictionary() {
        XCTAssertEqual(
            Set(HAR.Headers([
                "Accept": "text/html",
                "Content-Length": "348",
                "Cache-Control": "no-cache, no-store",
            ])),
            Set([
                HAR.Header(name: "Accept", value: "text/html"),
                HAR.Header(name: "Content-Length", value: "348"),
                HAR.Header(name: "Cache-Control", value: "no-cache, no-store"),
            ])
        )

        XCTAssertEqual(
            Set(HAR.Headers([
                "Content-Type": "text/html",
                "Content-Length": "348",
                "Set-Cookie": "theme=light, sessionToken=abc123; Expires=Wed, 09 Jun 2021 10:18:14 GMT",
            ])),
            Set([
                HAR.Header(name: "Content-Type", value: "text/html"),
                HAR.Header(name: "Content-Length", value: "348"),
                HAR.Header(name: "Set-Cookie", value: "theme=light, sessionToken=abc123; Expires=Wed, 09 Jun 2021 10:18:14 GMT"),
            ])
        )
    }
}
