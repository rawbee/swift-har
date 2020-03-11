import XCTest

@testable import HAR

final class EntriesTests: XCTestCase {
    func testURLMessage() throws {
        let har = try HAR(data: XCTUnwrap(fixtureData["Safari example.com.har"]))
        let harEntry = try XCTUnwrap(har.log.entries.first)
        let urlMessage = harEntry.toURLMessage()

        XCTAssertEqual(urlMessage.request.httpMethod, "GET")
        XCTAssertEqual(urlMessage.response.statusCode, 200)
        XCTAssertEqual(urlMessage.data.count, 1256)
    }

    func testRedacting() throws {
        let har = try HAR(data: XCTUnwrap(fixtureData["Safari jsbin.com.har"]))
        let entry = try XCTUnwrap(har.log.entries.first)

        let redactedEntry = entry.redacting(
            try NSRegularExpression(pattern: #"Cookie"#), placeholder: "redacted"
        )

        XCTAssertEqual(
            redactedEntry.request.headers.value(forName: "Cookie"),
            "redacted"
        )
        XCTAssertEqual(
            redactedEntry.request.cookies.first,
            HAR.Cookie(name: "last", value: "redacted")
        )
    }
}
