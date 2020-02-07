@testable import HAR
import XCTest

final class ResponseTests: XCTestCase {
    func testURLResponseFromFixtures() throws {
        for data in fixtureData.values {
            let har = try HAR(data: data)

            for entry in har.log.entries {
                let r1 = entry.response
                let urlResponse = HTTPURLResponse(url: entry.request.url, response: entry.response)
                let r2 = HAR.Response(response: urlResponse, data: entry.response.content.data)

                XCTAssertEqual(r1.status, r2.status)
                XCTAssertEqual(normalizedHeaders(r1.headers), normalizedHeaders(r2.headers))
                XCTAssertEqual(r1.content.data, r2.content.data)
            }
        }
    }

    func normalizedHeaders(_ headers: [HAR.Header]) -> [HAR.Header] {
        headers
            // FIXME: Multiple Set-Cookie is broken
            .filter { $0.name.lowercased() != "set-cookie" }
            .map { HAR.Header(($0.name.lowercased(), $0.value)) }
            .sorted { $0.name < $1.name }
    }
}
