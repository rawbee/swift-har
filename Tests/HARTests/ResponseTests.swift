import XCTest

@testable import HAR

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class ResponseTests: XCTestCase {
    func testCustomStringConvertible() {
        let content = HAR.Content(text: "Hello, World", mimeType: "text/plain")
        let response = HAR.Response(
            status: 200, statusText: "OK", httpVersion: "HTTP/1.1", cookies: [], headers: [],
            content: content, redirectURL: "", headersSize: -1, bodySize: content.size
        )

        XCTAssertEqual(
            String(describing: response),
            "200 OK  text/plain  12 bytes"
        )
    }

    func testCustomDebugStringConvertible() {
        let content = HAR.Content(text: "Hello, World", mimeType: "text/plain")
        let response = HAR.Response(
            status: 200, statusText: "OK", httpVersion: "HTTP/1.1", cookies: [], headers: [],
            content: content, redirectURL: "", headersSize: -1, bodySize: content.size
        )

        XCTAssertEqual(
            String(reflecting: response),
            "HAR.Response { 200 OK  text/plain  12 bytes }"
        )
    }

    func testSplitSetCookie() throws {
        let url = try XCTUnwrap(URL(string: "https://www.google.com/"))
        let headerFields = [
            "Content-Type": "text/html",
            "Set-Cookie":
                "A=1; Expires=Wed, 09 Jun 2021 10:18:14 GMT; path=/; domain=.google.com; Secure, B=2; Expires=Wed, 09 Jun 2021 10:18:14 GMT; path=/; domain=.google.com; HttpOnly",
        ]
        let urlResponse = try XCTUnwrap(
            HTTPURLResponse(
                url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headerFields
            ))
        let data = Data("Hello, World!".utf8)

        let response = HAR.Response(response: urlResponse, data: data)

        XCTAssertEqual(response.status, 200)
        XCTAssertEqual(response.statusText, "OK")
        XCTAssertEqual(
            Set(response.headers),
            Set([
                HAR.Header(name: "Content-Type", value: "text/html"),
                HAR.Header(
                    name: "Set-Cookie",
                    value: "A=1; Expires=Wed, 09 Jun 2021 10:18:14 GMT; path=/; domain=.google.com; Secure"
                ),
                HAR.Header(
                    name: "Set-Cookie",
                    value: "B=2; Expires=Wed, 09 Jun 2021 10:18:14 GMT; path=/; domain=.google.com; HttpOnly"
                ),
            ])
        )
    }

    func testURLResponseFromFixtures() throws {
        for (name, data) in fixtureData {
            let har = try HAR(data: data)

            for entry in har.log.entries {
                let r1 = entry.response
                let urlResponse = HTTPURLResponse(url: entry.request.url, response: entry.response)
                let r2 = HAR.Response(response: urlResponse, data: entry.response.content.data)

                XCTAssertEqual(r1.status, r2.status, name)
                XCTAssertEqual(normalizedHeaders(r1.headers), normalizedHeaders(r2.headers), name)
                XCTAssertEqual(r1.content.data, r2.content.data, name)
            }
        }
    }

    func normalizedHeaders(_ headers: [HAR.Header]) -> [HAR.Header] {
        headers
            // FIXME: Multiple Set-Cookie is broken
            .filter { $0.name.lowercased() != "set-cookie" }
            .map { HAR.Header(name: $0.name.lowercased(), value: $0.value) }
            .sorted { $0.name < $1.name }
    }

    func testScrubbing() throws {
        let response = HAR.Response(
            status: 200, statusText: "OK",
            headers: HAR.Headers([
                "Content-Type": "text/plain",
                "Content-Length": "12",
                "Set-Cookie": "A=1, B=2",
            ])
        )
        XCTAssertEqual(response.cookies.count, 2)

        let scrubbedResponse = response.scrubbing([
            .redactHeaderMatching(
                pattern: try NSRegularExpression(pattern: #"Cookie"#), placeholder: "redacted"
            ),
        ])

        XCTAssertEqual(
            Set(scrubbedResponse.headers),
            Set(
                HAR.Headers([
                    "Content-Type": "text/plain",
                    "Content-Length": "12",
                    "Set-Cookie": "redacted",
                ]))
        )
        XCTAssertEqual(
            scrubbedResponse.cookies,
            [
                HAR.Cookie(name: "A", value: "redacted", httpOnly: false, secure: false),
                HAR.Cookie(name: "B", value: "redacted", httpOnly: false, secure: false),
            ]
        )
    }
}
