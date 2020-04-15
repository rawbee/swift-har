import Foundation
import HAR

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension HAR.Entry {
    init?(_ request: URLRequest, _ response: URLResponse?, _ data: Data?, _ error: Error?) {
        /// - TODO: Record network errors as entries

        guard let response = response as? HTTPURLResponse else {
            return nil
        }

        self.init(
            request: HAR.Request(request: request),
            response: HAR.Response(response: response, data: data)
        )
    }

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
