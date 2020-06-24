import HAR

import struct Foundation.URL

#if canImport(FoundationNetworking)
import class FoundationNetworking.URLProtocol
import struct FoundationNetworking.URLRequest
import class FoundationNetworking.URLSession
import class FoundationNetworking.URLSessionConfiguration
#else
import class Foundation.URLProtocol
import struct Foundation.URLRequest
import class Foundation.URLSession
import class Foundation.URLSessionConfiguration
#endif

extension HAR {
    open class MockURLProtocol: URLProtocol {
        public static var url: URL?

        public static var configuration: URLSessionConfiguration {
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [self]
            return config
        }

        public static var session: URLSession {
            URLSession(configuration: configuration)
        }

        override public class func canInit(with _: URLRequest) -> Bool {
            true
        }

        override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }

        open func entry(for request: URLRequest, in log: HAR.Log) -> HAR.Entry {
            log.firstEntry
        }

        open func transform(_ entry: HAR.Entry) -> HAR.Entry {
            entry
        }

        override open func startLoading() {
            guard let url = Self.url else {
                preconditionFailure("\(Self.self).url was not set")
            }
            startLoading(url: url)
        }

        public func startLoading(url: URL) {
            HAR.load(
                contentsOf: url, orRecordRequest: request,
                completionHandler: { result in
                    self.didLoadEntry(
                        result.map { self.entry(for: self.request, in: $0.log) }
                    )
                }, transform: transform
            )
        }

        public func didLoadEntry(_ result: Result<HAR.Entry, Error>) {
            guard let client = self.client else { return }

            switch result {
            case .success(let entry):
                let (_, response, data) = entry.toURLMessage()
                client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client.urlProtocol(self, didLoad: data)
                client.urlProtocolDidFinishLoading(self)
            case .failure(let error):
                client.urlProtocol(self, didFailWithError: error)
            }
        }

        override public func stopLoading() {}
    }
}
