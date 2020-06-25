import HARTesting
import XCTest

#if canImport(FoundationNetworking)
import struct FoundationNetworking.URLRequest
#endif

final class XCTAwaitHTTPURLRequestTests: XCTestCase {
    func testAwaitHTTPURLRequest() throws {
        let fileURL = fixtureURL.appendingPathComponent("example.com.har")

        let url = try XCTUnwrap(URL(string: "http://example.com"))
        let urlRequest = URLRequest(url: url)

        let result = waitForHTTPURLRequest(urlRequest, mockedWith: fileURL)

        switch result {
        case .success((let data, let response)):
            XCTAssertEqual(data.count, 1256)
            XCTAssertEqual(response.statusCode, 200)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
}
