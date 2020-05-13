import HARTesting
import XCTest

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class XCTAwaitDataTaskTests: XCTestCase {
    func testAwaitDataTask() throws {
        let fileURL = fixtureURL.appendingPathComponent("example.com.har")

        let url = try XCTUnwrap(URL(string: "http://example.com"))
        let urlRequest = URLRequest(url: url)

        let result = awaitDataTask(request: urlRequest, mockedWith: fileURL)

        switch result {
        case .success((let data, let response)):
            XCTAssertEqual(data.count, 1256)

            let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)
            XCTAssertEqual(httpResponse.statusCode, 200)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
}
