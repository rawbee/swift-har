import HAR
import HARNetworking
import XCTest

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension XCTestCase {
    public func awaitDataTask(
        request: URLRequest,
        mockedProtocol mockProtocol: HAR.MockURLProtocol.Type = HAR.MockURLProtocol.self,
        mockedWith pathURL: URL,
        timeout seconds: TimeInterval = .infinity,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Result<(data: Data, response: HTTPURLResponse), URLError> {
        mockProtocol.url = pathURL
        mockProtocol.caller = (file: file, line: line)
        defer {
            mockProtocol.url = nil
            mockProtocol.caller = nil
        }

        let expectation = self.expectation(description: "Request")
        var result: Result<(data: Data, response: HTTPURLResponse), URLError>?

        let task = mockProtocol.session.dataTask(with: request) { data, response, error in
            if let error = error {
                let nserror = error as NSError
                result = .failure(URLError(_nsError: nserror))
            } else if let response = response as? HTTPURLResponse, let data = data {
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
