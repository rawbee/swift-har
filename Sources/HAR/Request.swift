import Foundation

extension HAR {
    /// This object contains detailed info about performed request.
    public struct Request: Equatable, Hashable, Codable, CustomStringConvertible,
        CustomDebugStringConvertible {
        // MARK: Properties

        /// Request method.
        public var method: String

        /// Absolute URL of the request (fragments are not included).
        public var url: URL

        /// Request HTTP Version.
        public var httpVersion: String = "HTTP/1.1"

        /// List of cookie objects.
        public var cookies: Cookies = []

        /// List of header objects.
        public var headers: Headers = []

        /// List of query parameter objects.
        public var queryString: QueryStrings = []

        /// Posted data info.
        public var postData: PostData?

        /// Total number of bytes from the start of the HTTP request message until (and
        /// including) the double CRLF before the body. Set to -1 if the info is not
        /// available.
        ///
        /// - Important: Should be ran when mutating `method`, `url`, `httpVersion` or
        /// `headers`.
        public var headersSize: Int = -1

        /// Size of the request body (POST data payload) in bytes. Set to -1 if the info
        /// is not available.
        public var bodySize: Int = -1

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?

        // MARK: Computed Properties

        /// Computed `cookies` from headers.
        public var computedCookies: Cookies {
            headers.value(forName: "Cookie").map { Cookies(fromCookieHeader: $0) } ?? []
        }

        /// Computed `queryString` from URL query string.
        public var computedQueryString: QueryStrings {
            URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.map(QueryString.init)
                ?? []
        }

        /// Computed `headersSize`.
        public var computedHeadersSize: Int {
            Data(headerText.utf8).count
        }

        /// Compute text representation of header for computing it's size.
        private var headerText: String {
            """
            \(method) \(url.relativePath) \(httpVersion)\r
            \(headers.map { "\($0.name): \($0.value)\r\n" }.joined())\r\n
            """
        }

        /// Computed `bodySize`.
        public var computedBodySize: Int {
            postData?.size ?? -1
        }

        // MARK: Initializers

        /// Create `Request` with HTTP method and url.
        ///
        /// - Parameter method: An HTTP method.
        /// - Parameter url: A URL.
        public init(
            method: String = "GET",
            url: URL,
            httpVersion: String = "HTTP/1.1",
            cookies: Cookies? = nil,
            headers: Headers = [],
            queryString: QueryStrings? = nil,
            postData: PostData? = nil,
            headersSize: Int? = nil,
            bodySize: Int? = nil,
            comment: String? = nil
        ) {
            self.method = method
            self.url = url
            self.httpVersion = httpVersion
            self.headers = headers
            self.postData = postData
            self.comment = comment
            self.cookies = cookies ?? computedCookies
            self.queryString = queryString ?? computedQueryString
            self.headersSize = headersSize ?? computedHeadersSize
            self.bodySize = bodySize ?? computedBodySize
        }

        // MARK: Encoding and Decoding

        /// Create Request from Decoder.
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            method = try container.decode(String.self, forKey: .method)
            url = try container.decode(URL.self, forKey: .url)
            httpVersion =
                try container.decodeIfPresent(String.self, forKey: .httpVersion)
                    ?? "HTTP/1.1"
            self.cookies = try container.decode(Cookies.self, forKey: .cookies)
            self.headers = try container.decode(Headers.self, forKey: .headers)
            self.queryString = try container.decode(QueryStrings.self, forKey: .queryString)
            self.postData = try container.decodeIfPresent(PostData.self, forKey: .postData)
            self.headersSize = try container.decodeIfPresent(Int.self, forKey: .headersSize) ?? -1
            self.bodySize = try container.decodeIfPresent(Int.self, forKey: .bodySize) ?? -1
            self.comment = try container.decodeIfPresent(String.self, forKey: .comment)
        }

        // MARK: Redacting sensitive data

        public mutating func scrub(_ operations: [ScrubOperation]) {
            let oldCookieValue = headers.value(forName: "Cookie")

            headers.scrub(operations)

            if let newCookieValue = headers.value(forName: "Cookie"), newCookieValue != oldCookieValue {
                for index in cookies.indices {
                    cookies[index].value = newCookieValue
                }
            }
        }

        public func scrubbing(_ operations: [ScrubOperation]) -> Self {
            var copy = self
            copy.scrub(operations)
            return copy
        }

        // MARK: Describing Requests

        /// A human-readable description for the data.
        public var description: String {
            "\(method) \(url.absoluteString)"
        }

        /// A human-readable debug description for the data.
        public var debugDescription: String {
            "HAR.Request { \(description) }"
        }

        public var curlDescription: String {
            String(describing: CurlCommand(request: self))
        }
    }
}
