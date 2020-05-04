import Foundation
import HAR

#if canImport(FoundationNetworking)
import FoundationNetworking
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

        // MARK: Instance Methods

        override public class func canInit(with _: URLRequest) -> Bool {
            true
        }

        override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }

        override open func startLoading() {
            guard let url = Self.url else {
                preconditionFailure("\(Self.self).url was not set")
            }
            startLoading(url: url)
        }

        public func startLoading(
            url: URL, transform: @escaping (HAR) -> HAR = { $0 },
            entrySelector: @escaping (HAR.Log) -> HAR.Entry = { $0.firstEntry }
        ) {
            HAR.load(contentsOf: url, orRecordRequest: request, transform: transform) { result in
                self.client?.urlProtocol(
                    self, didLoadEntryResult: result.map { har in entrySelector(har.log) }
                )
            }
        }

        override public func stopLoading() {}
    }
}
