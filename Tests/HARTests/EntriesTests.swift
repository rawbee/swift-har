import XCTest

@testable import HAR

final class EntriesTests: XCTestCase {
    override func setUp() {
        _ = fixtureData
    }

    func testURLMessage() throws {
        let har = try HAR(data: XCTUnwrap(fixtureData["Safari example.com.har"]))
        let harEntry = try XCTUnwrap(har.log.entries.first)
        let urlMessage = harEntry.toURLMessage()

        XCTAssertEqual(urlMessage.request.httpMethod, "GET")
        XCTAssertEqual(urlMessage.response.statusCode, 200)
        XCTAssertEqual(urlMessage.data.count, 1256)
    }

    func testScrubbing() throws {
        let har = try HAR(data: XCTUnwrap(fixtureData["Safari jsbin.com.har"]))
        let entry = try XCTUnwrap(har.log.entries.first)

        let scrubbedEntry = entry.scrubbing([
            .removeHeader(name: "User-Agent"),
            .redactHeaderMatching(
                pattern: try NSRegularExpression(pattern: #"Cookie"#), placeholder: "redacted"
            ),
        ])

        XCTAssertNil(
            scrubbedEntry.request.headers.value(forName: "User-Agent")
        )
        XCTAssertEqual(
            scrubbedEntry.request.headers.value(forName: "Cookie"),
            "redacted"
        )
        XCTAssertEqual(
            scrubbedEntry.request.cookies.first,
            HAR.Cookie(name: "last", value: "redacted")
        )
    }
}
