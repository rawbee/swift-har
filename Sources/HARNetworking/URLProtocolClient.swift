import HAR

#if canImport(FoundationNetworking)
import class FoundationNetworking.URLProtocol
import protocol FoundationNetworking.URLProtocolClient
#else
import class Foundation.URLProtocol
import protocol Foundation.URLProtocolClient
#endif

extension URLProtocolClient {
    // MARK: Instance Methods

    /// Tells the client that the protocol implementation has created a HAR Entry or Error for the request.
    public func urlProtocol(
        _ protocol: URLProtocol, didLoadEntryResult result: Result<HAR.Entry, Error>
    ) {
        switch result {
        case .success(let entry):
            urlProtocol(`protocol`, didLoadEntry: entry)
        case .failure(let error):
            urlProtocol(`protocol`, didFailWithError: error)
        }
    }

    /// Tells the client that the protocol implementation has created a HAR Entry for the request.
    public func urlProtocol(_ protocol: URLProtocol, didLoadEntry entry: HAR.Entry) {
        let (_, response, data) = entry.toURLMessage()
        urlProtocol(`protocol`, didReceive: response, cacheStoragePolicy: .notAllowed)
        urlProtocol(`protocol`, didLoad: data)
        urlProtocolDidFinishLoading(`protocol`)
    }
}
