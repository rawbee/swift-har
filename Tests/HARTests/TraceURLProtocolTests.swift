import HAR
import HARNetworking
import XCTest

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class TraceURLProtocolTests: XCTestCase {
    func testTrace() throws {
        let session = HAR.TraceURLProtocol.setUp()

        let url = try XCTUnwrap(URL(string: "http://example.com/"))
        let request = URLRequest(url: url)

        let expectation = self.expectation(description: "Request")

        session.dataTask(with: request) { data, urlResponse, error in
            XCTAssertNotNil(data)
            XCTAssertNotNil(urlResponse)
            XCTAssertNil(error)
            expectation.fulfill()
        }.resume()

        wait(for: [expectation], timeout: 5)

        let har = HAR.TraceURLProtocol.tearDown()

        guard let entry = har.log.entries.first else {
            XCTFail("no entries")
            return
        }

        XCTAssertEqual(entry.request.method, "GET")
        XCTAssertEqual(entry.request.url.absoluteString, "http://example.com/")
        XCTAssertGreaterThan(entry.request.headersSize, 0)
        XCTAssertEqual(entry.request.bodySize, 0)

        XCTAssertEqual(entry.response.status, 200)
        XCTAssertEqual(entry.response.statusText, "OK")
        XCTAssertGreaterThan(entry.response.headersSize, 0)
        XCTAssertGreaterThan(entry.response.bodySize, 0)
    }
}
