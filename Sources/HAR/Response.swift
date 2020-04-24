import Foundation

extension HAR {
    /// This object contains detailed info about the response.
    public struct Response: Equatable, Hashable, Codable, CustomStringConvertible,
        CustomDebugStringConvertible {
        // MARK: Properties

        /// Response status.
        public var status: Int

        /// Response status description.
        public var statusText: String

        /// Response HTTP Version.
        public var httpVersion: String

        /// List of cookie objects.
        public var cookies: Cookies = []

        /// List of header objects.
        public var headers: Headers = []

        /// Details about the response body.
        public var content: Content

        /// Redirection target URL from the Location response header.
        public var redirectURL: String

        /// Total number of bytes from the start of the HTTP response message until (and
        /// including) the double CRLF before the body. Set to -1 if the info is not
        /// available.
        ///
        /// The size of received response-headers is computed only from headers that are
        /// really received from the server. Additional headers appended by the browser
        /// are not included in this number, but they appear in the list of header
        /// objects.
        public var headersSize: Int = -1

        /// Size of the received response body in bytes. Set to zero in case of responses
        /// coming from the cache (304). Set to -1 if the info is not available.
        public var bodySize: Int = -1

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?

        // MARK: Computed Properties

        /// Computed `cookies` from headers.
        public var computedCookies: Cookies {
            headers.values(forName: "Set-Cookie")
                .map(Cookie.init(fromSetCookieHeader:))
        }

        /// Computed `headersSize`.
        public var computedHeadersSize: Int {
            Data(headerText.utf8).count
        }

        /// Compute text representation of header for computing it's size.
        private var headerText: String {
            """
            \(status) \(statusText)\r
            \(headers.map { "\($0.name): \($0.value)\r\n" }.joined())\r\n
            """
        }

        /// Computed `bodySize`.
        public var computedBodySize: Int {
            content.size
        }

        // MARK: Initializers

        /// Create response.
        public init(
            status: Int = 200, statusText: String = "OK", httpVersion: String = "HTTP/1.1",
            cookies: Cookies? = nil, headers: Headers = [], content: Content = .init(),
            redirectURL: String = "", headersSize: Int? = nil, bodySize: Int? = nil,
            comment: String? = nil
        ) {
            self.status = status
            self.statusText = statusText
            self.httpVersion = httpVersion
            self.content = content
            self.redirectURL = redirectURL
            self.headers = headers
            self.comment = comment
            self.cookies = cookies ?? computedCookies
            self.headersSize = headersSize ?? computedHeadersSize
            self.bodySize = bodySize ?? computedBodySize
        }

        // MARK: Encoding and Decoding

        /// Create Response from Decoder.
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            status = try container.decode(Int.self, forKey: .status)
            statusText = try container.decode(String.self, forKey: .statusText)
            httpVersion =
                try container.decodeIfPresent(String.self, forKey: .httpVersion)
                    ?? "HTTP/1.1"
            self.cookies = try container.decode(Cookies.self, forKey: .cookies)
            self.headers = try container.decode(Headers.self, forKey: .headers)
            self.content = try container.decode(Content.self, forKey: .content)
            self.redirectURL = try container.decode(String.self, forKey: .redirectURL)
            self.headersSize = try container.decodeIfPresent(Int.self, forKey: .headersSize) ?? -1
            self.bodySize = try container.decodeIfPresent(Int.self, forKey: .bodySize) ?? -1
            self.comment = try container.decodeIfPresent(String.self, forKey: .comment)
        }

        // MARK: Describing Responses

        /// A human-readable description for the data.
        public var description: String {
            [headerText, content.description].joined()
        }

        /// A human-readable debug description for the data.
        public var debugDescription: String {
            var strs: [String] = []

            strs.append("\(status) \(statusText)")
            strs.append(content.mimeType)

            let formatter = ByteCountFormatter()
            formatter.countStyle = .binary
            strs.append(formatter.string(fromByteCount: Int64(bodySize)))

            return "HAR.Response { \(strs.joined(separator: "  ")) }"
        }
    }
}
