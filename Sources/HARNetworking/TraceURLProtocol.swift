import Foundation
import HAR

#if canImport(FoundationNetworking)
import FoundationNetworking
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

        public override class func canInit(with request: URLRequest) -> Bool {
            true
        }

        public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }

        private var dataTask: URLSessionDataTask!

        public override func startLoading() {
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

        public override func stopLoading() {
            dataTask.cancel()
        }
    }
}
