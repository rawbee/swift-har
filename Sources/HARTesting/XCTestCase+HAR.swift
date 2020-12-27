import HAR
import HARNetworking
import XCTest

#if canImport(FoundationNetworking)
import class FoundationNetworking.HTTPURLResponse
import struct FoundationNetworking.URLRequest
#endif

public extension HAR.MockURLProtocol {
    static var caller: (file: StaticString, line: UInt)?
}

public extension XCTestCase {
#if swift(>=5.3)
    func waitForHTTPURLRequest(
        _ request: URLRequest,
        mockedProtocol mockProtocol: HAR.MockURLProtocol.Type = HAR.MockURLProtocol.self,
        mockedWith pathURL: URL,
        timeout seconds: TimeInterval = .infinity,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Result<(data: Data, response: HTTPURLResponse), URLError> {
        _waitForHTTPURLRequest(
            request,
            mockedProtocol: mockProtocol,
            mockedWith: pathURL,
            timeout: seconds,
            file: file,
            line: line
        )
    }
#else
    func waitForHTTPURLRequest(
        _ request: URLRequest,
        mockedProtocol mockProtocol: HAR.MockURLProtocol.Type = HAR.MockURLProtocol.self,
        mockedWith pathURL: URL,
        timeout seconds: TimeInterval = .infinity,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Result<(data: Data, response: HTTPURLResponse), URLError> {
        _waitForHTTPURLRequest(
            request,
            mockedProtocol: mockProtocol,
            mockedWith: pathURL,
            timeout: seconds,
            file: file,
            line: line
        )
    }
#endif

    private func _waitForHTTPURLRequest(
        _ request: URLRequest,
        mockedProtocol mockProtocol: HAR.MockURLProtocol.Type,
        mockedWith pathURL: URL,
        timeout seconds: TimeInterval = .infinity,
        file: StaticString,
        line: UInt
    ) -> Result<(data: Data, response: HTTPURLResponse), URLError> {
        guard request.url?.scheme == "http" || request.url?.scheme == "https" else {
            XCTFail("request url must have a HTTP scheme", file: file, line: line)
            return .failure(URLError(.badURL))
        }

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
                if nserror.domain == NSURLErrorDomain {
                    result = .failure(URLError(_nsError: nserror))
                } else {
                    result = .failure(URLError(.unknown))
                    XCTFail("MockURLProtocol errored with unknown domain: \(nserror.domain)")
                }
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
}
