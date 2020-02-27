@testable import HAR
import XCTest

final class EntriesTests: XCTestCase {
    func testURLMessage() throws {
        let har = try HAR(data: XCTUnwrap(fixtureData["Safari example.com.har"]))
        let harEntry = try XCTUnwrap(har.log.entries.first)
        let urlMessage = harEntry.toURLMessage()

        XCTAssertEqual(urlMessage.request.httpMethod, "GET")
        XCTAssertEqual(urlMessage.response.statusCode, 200)
        XCTAssertEqual(urlMessage.data.count, 1256)
    }
}
