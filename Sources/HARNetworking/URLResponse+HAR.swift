import HAR

import struct Foundation.Data
import struct Foundation.URL

#if canImport(FoundationNetworking)
import class FoundationNetworking.HTTPURLResponse
#else
import class Foundation.HTTPURLResponse
#endif

extension HAR.Response {
    // MARK: Initializers

    /// Creates a archived Response from a `HTTPURLResponse` and HTTP Body `Data`.
    public init(response: HTTPURLResponse, data: Data?) {
        let status = response.statusCode
        let statusText = Self.statusText(forStatusCode: response.statusCode)
        let headers = HAR.Headers(response.allHeaderFields).sorted()
        let content =
            data.map { HAR.Content(decoding: $0, mimeType: response.mimeType) }
                ?? HAR.Content()

        self.init(status: status, statusText: statusText, headers: headers, content: content)
    }

    // MARK: Type Methods

    private static func statusText(forStatusCode statusCode: Int) -> String {
        switch statusCode {
        case 200:
            return "OK"
        default:
            return HTTPURLResponse.localizedString(forStatusCode: statusCode).capitalized
        }
    }
}

extension HTTPURLResponse {
    // MARK: Initializers

    /// Creates a HTTP URL Request from a `HAR.Response`.
    ///
    /// - Parameter url: The URL from which the response was generated.
    /// - Parameter response: The HAR Response to reconstruct.
    public convenience init(url: URL, response: HAR.Response) {
        /// - Remark: initializer doesn't appear to have any failure cases
        self.init(
            url: url,
            statusCode: response.status,
            httpVersion: response.httpVersion,
            headerFields: response.headers.headersAsDictionary
        )!
    }
}
