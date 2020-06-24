import HAR
import HARNetworking
import XCTest

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class HARNetworkingTests: XCTestCase {
    func testRecord() throws {
        let url = try XCTUnwrap(URL(string: "http://example.com/"))
        let request = URLRequest(url: url)

        let expectation = self.expectation(description: "Record")
        var result: Result<HAR, Error>?

        HAR.record(request: request) {
            result = $0
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)

        let har = try XCTUnwrap(result?.get())

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

#if !os(Linux)
        XCTAssertGreaterThan(entry.time, 0)
        XCTAssertGreaterThan(entry.timings.send, 0)
        XCTAssertGreaterThan(entry.timings.wait, 0)
        XCTAssertGreaterThan(entry.timings.receive, 0)
#endif
    }
}
