import HAR

import struct Foundation.Data

#if canImport(FoundationNetworking)
import class FoundationNetworking.URLProtocol
import struct FoundationNetworking.URLRequest
import class FoundationNetworking.URLResponse
import class FoundationNetworking.URLSession
import class FoundationNetworking.URLSessionConfiguration
import class FoundationNetworking.URLSessionDataTask
#else
import class Foundation.URLProtocol
import struct Foundation.URLRequest
import class Foundation.URLResponse
import class Foundation.URLSession
import class Foundation.URLSessionConfiguration
import class Foundation.URLSessionDataTask
#endif

extension HAR {
    public class TraceURLProtocol: URLProtocol {
        private static var log: HAR.Log!

        public static func setUp() -> URLSession {
            log = .init()
            return session
        }

        public static func tearDown() -> HAR {
            defer { self.log = nil }
            return HAR(log: log)
        }

        static var session: URLSession {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [self]

            return URLSession(configuration: configuration)
        }

        override public class func canInit(with request: URLRequest) -> Bool {
            true
        }

        override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }

        private var dataTask: URLSessionDataTask!

        override public func startLoading() {
            dataTask = URLSession.shared.dataTask(
                with: request, completionHandler: didLoad
            )
            dataTask.resume()
        }

        private func didLoad(data: Data?, urlResponse: URLResponse?, error: Error?) {
            if let entry = HAR.Entry(request, urlResponse, data, error) {
                Self.log.entries.append(entry)
            }

            guard let client = self.client else { return }

            if let error = error {
                client.urlProtocol(self, didFailWithError: error)
            } else if let urlResponse = urlResponse, let data = data {
                client.urlProtocol(self, didReceive: urlResponse, cacheStoragePolicy: .notAllowed)
                client.urlProtocol(self, didLoad: data)
                client.urlProtocolDidFinishLoading(self)
            }
        }

        override public func stopLoading() {
            dataTask.cancel()
        }
    }
}
