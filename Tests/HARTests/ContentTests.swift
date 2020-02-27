@testable import HAR
import XCTest

final class ContentTests: XCTestCase {
    func testInitEmpty() {
        let content = HAR.Content()
        XCTAssertEqual(content.mimeType, "application/octet-stream")
        XCTAssertEqual(content.size, 0)
        XCTAssertEqual(content.text, nil)
    }

    func testInitFromString() {
        var content: HAR.Content

        content = HAR.Content(text: "foo=bar", mimeType: "application/x-www-form-urlencoded")
        XCTAssertEqual(content.text, "foo=bar")
        XCTAssertEqual(content.size, 7)

        content = HAR.Content(text: "PGh0bWw+PGhlYWQ+PC9oZWFkPjxib2R5Lz48L2h0bWw+XG4=", encoding: "base64", mimeType: "text/html; charset=utf-8")
        XCTAssertEqual(content.size, 35)
        XCTAssertEqual(content.data.count, 35)
        XCTAssertEqual(content.text, "PGh0bWw+PGhlYWQ+PC9oZWFkPjxib2R5Lz48L2h0bWw+XG4=")
        XCTAssertEqual(content.encoding, "base64")
    }

    func testInitDecodingData() throws {
        let data = try XCTUnwrap(Data(base64Encoded: "PGh0bWw+PGhlYWQ+PC9oZWFkPjxib2R5Lz48L2h0bWw+XG4="))
        let content = HAR.Content(decoding: data, mimeType: "text/html; charset=utf-8")

        XCTAssertEqual(content.size, 35)
        XCTAssertEqual(content.data.count, 35)
        XCTAssertEqual(content.text, "<html><head></head><body/></html>\\n")
        XCTAssertEqual(content.encoding, nil)
    }
}
