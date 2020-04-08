import Foundation
import HAR

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension HAR.Entry {
    // MARK: Instance Methods

    /// Create Foundation URL request and response for archived entry.
    public func toURLMessage() -> (request: URLRequest, response: HTTPURLResponse, data: Data) {
        (
            request: URLRequest(request: request),
            response: HTTPURLResponse(url: request.url, response: response),
            data: response.content.data
        )
    }
}
