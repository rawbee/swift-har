import Foundation
import HAR

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension HAR.Request {
    /// Creates a HAR Request from a URL Request.
    ///
    /// - Parameter request: A URL Request.
    public init(request: URLRequest, data: Data? = nil) {
        /// - Invariant: `URLRequest.httpMethod` defaults to `"GET"`
        let method = request.httpMethod ?? "GET"

        /// Empty URL fallback to cover edge case of nil URLRequest.url
        let url = request.url ?? URL(string: "about:blank")!

        let headers: HAR.Headers = request.allHTTPHeaderFields.map { HAR.Headers($0) }?.sorted() ?? []

        var bodySize = 0
        var postData: HAR.PostData?
        if let data = (data ?? request.httpBody) {
            bodySize = data.count
            postData = HAR.PostData(
                parsingData: data,
                mimeType: headers.value(forName: "Content-Type")
            )
        }

        self.init(method: method, url: url, headers: headers, postData: postData, bodySize: bodySize)
    }
}

extension URLRequest {
    // MARK: Initializers

    /// Creates a URL Request from a `HAR.Request`.
    ///
    /// - Parameter request: A `HAR.Request`.
    public init(request: HAR.Request) {
        self.init(url: request.url)
        httpMethod = request.method
        for header in request.headers {
            addValue(header.value, forHTTPHeaderField: header.name)
        }
        httpBody = request.postData?.data
    }

    /// If body is represented as a stream, buffer it as Data on `httpBody`.
    mutating func bufferHTTPBodyStream() {
        // Ensure non-GET and body is already set
        guard httpMethod != "GET", httpBody == nil else {
            return
        }

        // Ensure bodyStream is available
        guard let httpBodyStream = self.httpBodyStream else {
            return
        }

        httpBody = try? Data(reading: httpBodyStream)
    }
}
