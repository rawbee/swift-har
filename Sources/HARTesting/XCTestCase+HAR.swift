import HAR
import HARNetworking
import XCTest

extension XCTestCase {
    func awaitDataTask(
        request: URLRequest,
        mockedProtocol mockProtocol: HAR.MockURLProtocol.Type = HAR.MockURLProtocol.self,
        mockedWith pathURL: URL,
        timeout seconds: TimeInterval = .infinity
    ) -> Result<(data: Data, response: URLResponse), URLError> {
        mockProtocol.url = pathURL
        defer { mockProtocol.url = nil }

        let expectation = self.expectation(description: "Request")
        var result: Result<(data: Data, response: URLResponse), URLError>?

        let task = mockProtocol.session.dataTask(with: request) { data, response, error in
            if let error = error {
                let nserror = error as NSError
                result = .failure(URLError(_nsError: nserror))
            } else if let response = response, let data = data {
                result = .success((data, response))
            } else {
                result = .failure(URLError(.unknown))
                XCTFail("URLSessionDataTask completed without response or error")
            }
            expectation.fulfill()
        }
        task.resume()

        wait(for: [expectation], timeout: seconds)

        if let result = result {
            return result
        } else {
            return .failure(URLError(.timedOut))
        }
    }

#if !os(Linux)
    public func recordNetworkingAttachment() -> URLSession {
        addTeardownBlock { self.add(HAR.TraceURLProtocol.tearDown().attachment) }
        return HAR.TraceURLProtocol.setUp()
    }
#endif
}
