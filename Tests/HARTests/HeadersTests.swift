import XCTest

@testable import HAR

final class HeadersTests: XCTestCase {
    func testEquatable() {
        XCTAssertEqual(
            HAR.Header(name: "Content-Type", value: "text/html"),
            HAR.Header(name: "Content-Type", value: "text/html")
        )
        XCTAssertEqual(
            HAR.Header(name: "Content-Type", value: "text/html"),
            HAR.Header(name: "content-type", value: "text/html")
        )

        XCTAssertNotEqual(
            HAR.Header(name: "Content-Type", value: "text/html"),
            HAR.Header(name: "Content-Type", value: "text/plain")
        )
        XCTAssertNotEqual(
            HAR.Header(name: "Accept", value: "text/html"),
            HAR.Header(name: "Content-Type", value: "text/html")
        )
    }

    func testComparable() {
        XCTAssertLessThan(
            HAR.Header(name: "Date", value: "Wed, 21 Oct 2015 07:28:00 GMT"),
            HAR.Header(name: "Accept", value: "text/html")
        )
        XCTAssertGreaterThan(
            HAR.Header(name: "Accept", value: "text/html"),
            HAR.Header(name: "Date", value: "Wed, 21 Oct 2015 07:28:00 GMT")
        )

        XCTAssertLessThan(
            HAR.Header(name: "Accept", value: "text/html"),
            HAR.Header(name: "Content-Length", value: "42")
        )
        XCTAssertGreaterThan(
            HAR.Header(name: "Content-Length", value: "42"),
            HAR.Header(name: "Accept", value: "text/html")
        )

        XCTAssertLessThan(
            HAR.Header(name: "Content-Length", value: "42"),
            HAR.Header(name: "Content-Type", value: "text/html")
        )
    }

    func testHashable() {
        let set = Set([
            HAR.Header(name: "Content-Type", value: "text/html"),
            HAR.Header(name: "content-type", value: "text/html"),
            HAR.Header(name: "Content-Length", value: "42"),
        ])
        XCTAssertEqual(set.count, 2)
    }

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

    func testValuesForName() {
        let headers = [
            HAR.Header(name: "Content-Type", value: "text/html"),
            HAR.Header(name: "Content-Length", value: "348"),
            HAR.Header(name: "Set-Cookie", value: "theme=light"),
            HAR.Header(
                name: "Set-Cookie", value: "sessionToken=abc123; Expires=Wed, 09 Jun 2021 10:18:14 GMT"
            ),
        ]

        XCTAssertEqual(headers.values(forName: "Content-Type"), ["text/html"])
        XCTAssertEqual(
            headers.values(forName: "set-cookie"),
            [
                "theme=light",
                "sessionToken=abc123; Expires=Wed, 09 Jun 2021 10:18:14 GMT",
            ]
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
                HAR.Header(
                    name: "Set-Cookie", value: "sessionToken=abc123; Expires=Wed, 09 Jun 2021 10:18:14 GMT"
                ),
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
            Set(
                HAR.Headers([
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
            Set(
                HAR.Headers([
                    "Content-Type": "text/html",
                    "Content-Length": "348",
                    "Set-Cookie": "theme=light, sessionToken=abc123; Expires=Wed, 09 Jun 2021 10:18:14 GMT",
                ])),
            Set([
                HAR.Header(name: "Content-Type", value: "text/html"),
                HAR.Header(name: "Content-Length", value: "348"),
                HAR.Header(name: "Set-Cookie", value: "theme=light"),
                HAR.Header(
                    name: "Set-Cookie", value: "sessionToken=abc123; Expires=Wed, 09 Jun 2021 10:18:14 GMT"
                ),
            ])
        )
    }

    func testIsNamedString() {
        XCTAssertTrue(HAR.Header(name: "Content-Type", value: "text/html").isNamed("Content-Type"))
        XCTAssertTrue(HAR.Header(name: "Content-Type", value: "text/html").isNamed("content-type"))
        XCTAssertTrue(HAR.Header(name: "content-type", value: "text/html").isNamed("Content-Type"))
        XCTAssertFalse(HAR.Header(name: "Content-Length", value: "text/html").isNamed("Content-Type"))
    }

    func testIsNamedRegexp() throws {
        XCTAssertTrue(
            HAR.Header(name: "Content-Type", value: "text/html").isNamed(
                try NSRegularExpression(pattern: #"content"#, options: .caseInsensitive)))
        XCTAssertTrue(
            HAR.Header(name: "content-type", value: "text/html").isNamed(
                try NSRegularExpression(pattern: #"content"#, options: .caseInsensitive)))
        XCTAssertTrue(
            HAR.Header(name: "Content-Length", value: "text/html").isNamed(
                try NSRegularExpression(pattern: #"content"#, options: .caseInsensitive)))
        XCTAssertFalse(
            HAR.Header(name: "Accept", value: "text/html").isNamed(
                try NSRegularExpression(pattern: #"content"#, options: .caseInsensitive)))
    }

    func testRedacting() throws {
        XCTAssertEqual(
            Set(
                HAR.Headers([
                    "Content-Type": "text/html",
                    "Content-Length": "348",
                    "Set-Cookie": "theme=light, sessionToken=abc123; Expires=Wed, 09 Jun 2021 10:18:14 GMT",
                ]).scrubbing([
                    .redactHeaderMatching(
                        pattern: try NSRegularExpression(pattern: #"Cookie"#, options: .caseInsensitive),
                        placeholder: "redacted"
                    ),
                ])),
            Set(
                HAR.Headers([
                    "Content-Type": "text/html",
                    "Content-Length": "348",
                    "Set-Cookie": "redacted",
                ]))
        )
    }
}
