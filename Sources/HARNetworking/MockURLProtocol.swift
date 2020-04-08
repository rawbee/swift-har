import Foundation
import HAR

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension HAR {
    open class MockURLProtocol: URLProtocol {
        // MARK: Instance Properties

        public static var configuration: URLSessionConfiguration {
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [Self.self]
            return config
        }

        public static var session: URLSession {
            URLSession(configuration: configuration)
        }

        // MARK: Instance Methods

        public override class func canInit(with _: URLRequest) -> Bool {
            true
        }

        public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }

        open override func startLoading() {
            fatalError("URLProtocol.startLoading must be implemented")
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

        public override func stopLoading() {}
    }
}
