@testable import HAR
import XCTest

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class ResponseTests: XCTestCase {
    func testCustomStringConvertible() {
        let content = HAR.Content(text: "Hello, World", mimeType: "text/plain")
        let response = HAR.Response(status: 200, statusText: "OK", httpVersion: "HTTP/1.1", cookies: [], headers: [], content: content, redirectURL: "", headersSize: -1, bodySize: content.size)

        XCTAssertEqual(
            String(describing: response),
            "200 OK  text/plain  12 bytes"
        )
    }

    func testCustomDebugStringConvertible() {
        let content = HAR.Content(text: "Hello, World", mimeType: "text/plain")
        let response = HAR.Response(status: 200, statusText: "OK", httpVersion: "HTTP/1.1", cookies: [], headers: [], content: content, redirectURL: "", headersSize: -1, bodySize: content.size)

        XCTAssertEqual(
            String(reflecting: response),
            "HAR.Response { 200 OK  text/plain  12 bytes }"
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
}
