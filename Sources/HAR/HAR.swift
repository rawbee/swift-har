//===----------------------------------------------------------------------===//
//
// SwiftHAR
// https://github.com/josh/SwiftHAR
//
// Copyright (c) 2020 Joshua Peek
// Licensed under MIT License
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
//===----------------------------------------------------------------------===//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct HAR {
    public var log: Log

    // MARK: - Log

    /// This object represents the root of exported data.
    ///
    /// There is one `Page` object for every exported web page and one `Entry` object
    /// for every HTTP request. In case when an HTTP trace tool isn't able to group
    /// requests by a page, the `pages` object is empty and individual requests doesn't
    /// have a parent page.
    public struct Log {
        /// Version number of the format. If empty, string "1.1" is assumed by default.
        public var version: String = "1.2"

        /// Name and version info of the log creator application.
        public var creator: Creator = Creator.defaultCreator

        /// Name and version info of used browser.
        public var browser: Browser?

        /// List of all exported (tracked) pages. Leave out this field if the
        /// application does not support grouping by pages.
        public var pages: Pages?

        /// List of all exported (tracked) requests.
        public var entries: Entries = []

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    // MARK: - Creator

    public struct Creator {
        static let defaultCreator = Creator(name: "SwiftHAR", version: "0.1.0")

        /// Name of the application/browser used to export the log.
        public var name: String

        /// Version of the application/browser used to export the log.
        public var version: String

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    // MARK: - Browser

    public struct Browser {
        /// Name of the application/browser used to export the log.
        public var name: String

        /// Version of the application/browser used to export the log.
        public var version: String

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    // MARK: - Pages

    /// This object represents list of exported pages.
    public struct Page {
        /// Date and time stamp for the beginning of the page load.
        public var startedDateTime: Date

        /// Unique identifier of a page within the `Log`. Entries use it to refer the
        /// parent page.
        public var id: String

        /// Page title.
        public var title: String = ""

        /// Detailed timing info about page load.
        public var pageTimings: PageTiming = PageTiming()

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    public typealias Pages = [Page]

    // MARK: - PageTimings

    /// This object describes timings for various events (states) fired during the page
    /// load. All times are specified in milliseconds. If a time info is not available
    /// appropriate field is set to -1.
    ///
    /// Depending on the browser, onContentLoad property represents `DOMContentLoad`
    /// event or `document.readyState == interactive`.
    public struct PageTiming {
        /// Content of the page loaded. Number of milliseconds since page load started
        /// (`page.startedDateTime`). Use -1 if the timing does not apply to the current
        /// request.
        public var onContentLoad: Double? = -1

        /// Page is loaded (onLoad event fired). Number of milliseconds since page load
        /// started (`page.startedDateTime`). Use -1 if the timing does not apply to the
        /// current request.
        public var onLoad: Double? = -1

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    // MARK: - Entries

    /// This object represents an array with all exported HTTP requests. Sorting entries
    /// by `startedDateTime` (starting from the oldest) is preferred way how to export
    /// data since it can make importing faster. However the reader application should
    /// always make sure the array is sorted (if required for the import).
    public struct Entry {
        /// Reference to the parent page. Leave out this field if the application does
        /// not support grouping by pages.
        public var pageref: String?

        /// Date and time stamp of the request start.
        public var startedDateTime: Date = Date()

        /// Total elapsed time of the request in milliseconds. This is the sum of all
        /// timings available in the timings object (i.e. not including -1 values) .
        ///
        /// - Invariant: The time value for the request must be equal to the sum of the
        /// timings supplied in this section (excluding any -1 values).
        public var time: Double = 0

        /// Detailed info about the request.
        public var request: Request

        /// Detailed info about the response.
        public var response: Response

        /// Info about cache usage.
        public var cache: Cache = Cache()

        /// Detailed timing info about request/response round trip.
        public var timings: Timing = Timing(send: 0, wait: 0, receive: 0)

        /// IP address of the server that was connected (result of DNS resolution).
        ///
        /// - Version: 1.2
        public var serverIPAddress: String?

        /// Unique ID of the parent TCP/IP connection, can be the client or server port
        /// number. Note that a port number doesn't have to be unique identifier in cases
        /// where the port is shared for more connections. If the port isn't available
        /// for the application, any other unique connection ID can be used instead (e.g.
        /// connection index). Leave out this field if the application doesn't support
        /// this info.
        ///
        /// - Version: 1.2
        public var connection: String?

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    public typealias Entries = [Entry]

    // MARK: - Request

    /// This object contains detailed info about performed request.
    public struct Request {
        /// Request method.
        public var method: String = "GET"

        /// Absolute URL of the request (fragments are not included).
        public var url: URL

        /// Request HTTP Version.
        public var httpVersion: String = "HTTP/1.1"

        /// List of cookie objects.
        public var cookies: Cookies = []

        /// List of header objects.
        public var headers: Headers = []

        /// Find header value for name.
        ///
        /// Header names are case-insensitive.
        ///
        /// - Parameter name: The HTTP Header name.
        public func value(forHTTPHeaderField name: String) -> String? {
            let lowercasedName = name.lowercased()
            return headers.first(where: { lowercasedName == $0.name.lowercased() })?.value
        }

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

        /// Create `Request` with HTTP method and url.
        ///
        /// - Parameter method: An HTTP method.
        /// - Parameter url: A URL.
        init(method: String, url: URL) {
            self.method = method
            self.url = url

            queryString = computedQueryString
            headersSize = computedHeadersSize
        }
    }

    // MARK: - Response

    /// This object contains detailed info about the response.
    public struct Response {
        /// Response status.
        public var status: Int = 200

        /// Response status description.
        public var statusText: String = "OK"

        /// Response HTTP Version.
        public var httpVersion: String = "HTTP/1.1"

        /// List of cookie objects.
        public var cookies: Cookies = []

        /// List of header objects.
        public var headers: Headers = []

        /// Details about the response body.
        public var content: Content = HAR.Content()

        /// Redirection target URL from the Location response header.
        public var redirectURL: String = ""

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
    }

    // MARK: - Cookies

    /// This object contains list of all cookies (used in `Request` and `Response`
    /// objects).
    public struct Cookie {
        /// The name of the cookie.
        public var name: String

        /// The cookie value.
        public var value: String

        /// The path pertaining to the cookie.
        public var path: String?

        // The host of the cookie.
        public var domain: String?

        /// Cookie expiration time.
        public var expires: Date?

        /// Set to true if the cookie is HTTP only, false otherwise.
        public var httpOnly: Bool?

        /// True if the cookie was transmitted over ssl, false otherwise.
        ///
        /// - Version: 1.2
        public var secure: Bool?

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?

        /// The SameSite cross-origin policy of the cookie.
        ///
        /// Possible values: `"strict"`, `"lax"`, `"none"`
        ///
        /// - Version: Unspecified
        public var sameSite: String?
    }

    public typealias Cookies = [Cookie]

    // MARK: - Headers

    /// This object contains list of all headers (used in `Request` and `Response`
    /// objects).
    public struct Header {
        public var name: String
        public var value: String

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    public typealias Headers = [Header]

    // MARK: - QueryString

    /// This object contains list of all parameters & values parsed from a query string,
    /// if any (embedded in `Request` object).
    public struct QueryString {
        public var name: String
        public var value: String

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    public typealias QueryStrings = [QueryString]

    // MARK: - PostData

    /// This object describes posted data, if any (embedded in `Request` object).
    public struct PostData {
        /// Mime type of posted data.
        public var mimeType: String

        /// List of posted parameters (in case of URL encoded parameters).
        ///
        /// - Invariant: Text and params fields are mutually exclusive.
        public var params: Params

        /// Plain text posted data
        ///
        /// - Invariant: Text and params fields are mutually exclusive.
        public var text: String

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    // MARK: - Params

    /// List of posted parameters, if any (embedded in `PostData` object).
    public struct Param {
        /// Name of a posted parameter.
        public var name: String

        /// Value of a posted parameter or content of a posted file.
        public var value: String?

        /// Name of a posted file.
        public var fileName: String?

        /// Content type of a posted file.
        public var contentType: String?

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    public typealias Params = [Param]

    // MARK: - Content

    /// This object describes details about response content (embedded in `Response`
    /// object).
    public struct Content {
        /// Length of the returned content in bytes. Should be equal to
        /// `response.bodySize` if there is no compression and bigger when the content
        /// has been compressed.
        public var size: Int

        /// Number of bytes saved. Leave out this field if the information is not
        /// available.
        public var compression: Int?

        /// MIME type of the response text (value of the Content-Type response header).
        /// The charset attribute of the MIME type is included (if available).
        public var mimeType: String

        ///  Response body sent from the server or loaded from the browser cache. This
        /// field is populated with textual content only. The text field is either HTTP
        /// decoded text or a encoded (e.g. "base64") representation of the response
        /// body. Leave out this field if the information is not available.
        ///
        /// Before setting the text field, the HTTP response is decoded (decompressed &
        /// unchunked), than trans-coded from its original character set into UTF-8.
        /// Additionally, it can be encoded using e.g. base64. Ideally, the application
        /// should be able to unencode a base64 blob and get a byte-for-byte identical
        /// resource to what the browser operated on.
        public var text: String?

        /// Encoding used for response text field e.g "base64". Leave out this field if
        /// the text field is HTTP decoded (decompressed & unchunked), than trans-coded
        /// from its original character set into UTF-8.
        ///
        /// Encoding field is useful for including binary responses (e.g. images) into
        /// the HAR file.
        ///
        /// - Version: 1.2
        public var encoding: String?

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    // MARK: - Cache

    /// This objects contains info about a request coming from browser cache.
    public struct Cache {
        // State of a cache entry before the request. Leave out this field if the
        /// information is not available.
        public var beforeRequest: CacheEntry?

        /// State of a cache entry after the request. Leave out this field if the
        /// information is not available.
        public var afterRequest: CacheEntry?

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    public struct CacheEntry {
        /// Expiration time of the cache entry.
        public var expires: Date?

        /// The last time the cache entry was opened.
        public var lastAccess: Date

        /// Etag
        public var eTag: String

        /// The number of times the cache entry has been opened.
        public var hitCount: Int

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    // MARK: - Timings

    /// This object describes various phases within request-response round trip. All
    /// times are specified in milliseconds.
    public struct Timing {
        /// Time spent in a queue waiting for a network connection. Use -1 if the timing
        /// does not apply to the current request.
        public var blocked: Double? = -1

        /// DNS resolution time. The time required to resolve a host name. Use -1 if the
        /// timing does not apply to the current request.
        public var dns: Double? = -1

        ///  Time required to create TCP connection. Use -1 if the timing does not apply
        /// to the current request.
        public var connect: Double? = -1

        /// Time required to send HTTP request to the server.
        public var send: Double

        /// Waiting for a response from the server.
        public var wait: Double

        /// Time required to read entire response from the server (or cache).
        public var receive: Double

        /// Time required for SSL/TLS negotiation. If this field is defined then the
        /// time is also included in the connect field (to ensure backward compatibility
        /// with HAR 1.1). Use -1 if the timing does not apply to the current request.
        ///
        /// - Version: 1.2
        public var ssl: Double? = -1

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }
}

// MARK: - HAR

extension HAR: Equatable {}

extension HAR: Hashable {}

extension HAR: Codable {
    /// Creates a `HAR` from the contents of a file URL.
    ///
    /// - Parameter url: Path to `.har` file.
    public init(contentsOf url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    /// Return ISO 8601 date formatter.
    ///
    /// Uses the format `YYYY-MM-DDThh:mm:ss.sTZD` to return a date such as
    /// `2009-07-24T19:20:30.45+01:00`.
    private static func makeDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSZZZZZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }

    /// Initialize singleton ISO 8601 date formatter.
    private static let dateFormatter: DateFormatter = makeDateFormatter()

    /// Creates a `HAR` from JSON `Data`.
    ///
    /// - Parameter data: UTF-8 JSON data.
    public init(data: Data) throws {
        let decoder = JSONDecoder()

        decoder.dateDecodingStrategy = .custom { (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)

            if let date = Self.dateFormatter.date(from: dateStr) {
                return date
            }

            throw Swift.DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "invalid date: \(dateStr)")
        }

        self = try decoder.decode(Self.self, from: data)
    }

    /// Returns a HAR encoded as JSON `Data`.
    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .formatted(Self.dateFormatter)
        return try encoder.encode(self)
    }
}

// MARK: - Log

extension HAR.Log: Equatable {}

extension HAR.Log: Hashable {}

extension HAR.Log: Codable {}

// MARK: - Creator

extension HAR.Creator: Equatable {}

extension HAR.Creator: Hashable {}

extension HAR.Creator: CustomStringConvertible {
    /// A human-readable description for the data.
    public var description: String {
        "\(name)/\(version)"
    }
}

extension HAR.Creator: CustomDebugStringConvertible {
    /// A human-readable debug description for the data.
    public var debugDescription: String {
        "HAR.Browser { \(description) }"
    }
}

extension HAR.Creator: Codable {}

// MARK: - Browser

extension HAR.Browser: Equatable {}

extension HAR.Browser: Hashable {}

extension HAR.Browser: CustomStringConvertible {
    /// A human-readable description for the data.
    public var description: String {
        "\(name)/\(version)"
    }
}

extension HAR.Browser: CustomDebugStringConvertible {
    /// A human-readable debug description for the data.
    public var debugDescription: String {
        "HAR.Browser { \(description) }"
    }
}

extension HAR.Browser: Codable {}

// MARK: - Pages

extension HAR.Page: Equatable {}

extension HAR.Page: Hashable {}

extension HAR.Page: CustomStringConvertible {
    /// A human-readable description for the data.
    public var description: String {
        "\(startedDateTime): \(id) \"\(title)\" - \(String(describing: pageTimings))"
    }
}

extension HAR.Page: CustomDebugStringConvertible {
    /// A human-readable debug description for the data.
    public var debugDescription: String {
        "HAR.Page { \(description) }"
    }
}

extension HAR.Page: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Self.CodingKeys.self)

        startedDateTime = try container.decode(Date.self, forKey: .startedDateTime)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        pageTimings = try container.decode(HAR.PageTiming.self, forKey: .pageTimings)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
    }
}

// MARK: - PageTimings

extension HAR.PageTiming: Equatable {}

extension HAR.PageTiming: Hashable {}

extension HAR.PageTiming: CustomStringConvertible {
    /// A human-readable description for the data.
    public var description: String {
        "onContentLoad: \(onContentLoad ?? -1), onLoad: \(onLoad ?? -1)"
    }
}

extension HAR.PageTiming: CustomDebugStringConvertible {
    /// A human-readable debug description for the data.
    public var debugDescription: String {
        "HAR.PageTiming { \(description) }"
    }
}

extension HAR.PageTiming: Codable {}

// MARK: - Entries

extension HAR.Entry: Equatable {}

extension HAR.Entry: Hashable {}

extension HAR.Entry: Codable {}

extension HAR.Entry {
    /// Cookie property computed from timings.
    public var computedTime: Double {
        timings.total
    }
}

// MARK: - Request

extension HAR.Request: Equatable {}

extension HAR.Request: Hashable {}

extension HAR.Request: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Self.CodingKeys.self)

        method = try container.decode(String.self, forKey: .method)
        url = try container.decode(URL.self, forKey: .url)
        httpVersion = try container.decodeIfPresent(String.self, forKey: .httpVersion)
            ?? "HTTP/1.1"
        cookies = try container.decode([HAR.Cookie].self, forKey: .cookies)
        headers = try container.decode([HAR.Header].self, forKey: .headers)
        queryString = try container.decode([HAR.QueryString].self, forKey: .queryString)
        postData = try container.decodeIfPresent(HAR.PostData.self, forKey: .postData)
        headersSize = try container.decodeIfPresent(Int.self, forKey: .headersSize) ?? -1
        bodySize = try container.decodeIfPresent(Int.self, forKey: .bodySize) ?? -1
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
    }
}

extension HAR.Request {
    /// Cookie property computed from headers
    public var computedCookies: [HAR.Cookie] {
        if let value = value(forHTTPHeaderField: "Cookie") {
            return HAR.Cookies(fromCookieHeader: value)
        }
        return []
    }

    /// queryString property computed from URL query string.
    public var computedQueryString: [HAR.QueryString] {
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems {
            return queryItems.map { HAR.QueryString($0) }
        }
        return []
    }

    /// Computed `headerSize`.
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
}

extension URLRequest {
    /// Creates a URL Request from a `HAR.Request`.
    ///
    /// - Parameter request: A `HAR.Request`.
    init(request: HAR.Request) {
        self.init(url: request.url)
        httpMethod = request.method
        for header in request.headers {
            addValue(header.value, forHTTPHeaderField: header.name)
        }
        httpBody = request.postData?.data
    }
}

extension HAR.Request {
    /// Creates a HAR Request from a URL Request.
    ///
    /// - Parameter request: A URL Request.
    init(request: URLRequest) {
        /// Empty URL fallback to cover edge case of nil URLRequest.url
        url = URL(string: "about:blank")!
        if let url = request.url {
            self.url = url
        }

        queryString = computedQueryString

        /// - Invariant: `URLRequest.httpMethod` defaults to `"GET"`
        method = request.httpMethod ?? "GET"

        if let headers = request.allHTTPHeaderFields {
            self.headers = headers.map { HAR.Header(name: $0.key, value: $0.value) }
        }

        cookies = computedCookies
        headersSize = computedHeadersSize

        if let data = request.httpBody {
            postData = HAR.PostData(
                parsingData: data,
                mimeType: value(forHTTPHeaderField: "Content-Type"))
            bodySize = data.count
        }
    }
}

// MARK: - Response

extension HAR.Response: Equatable {}

extension HAR.Response: Hashable {}

extension HAR.Response: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Self.CodingKeys.self)

        status = try container.decode(Int.self, forKey: .status)
        statusText = try container.decode(String.self, forKey: .statusText)
        httpVersion = try container.decodeIfPresent(String.self, forKey: .httpVersion)
            ?? "HTTP/1.1"
        cookies = try container.decode([HAR.Cookie].self, forKey: .cookies)
        headers = try container.decode([HAR.Header].self, forKey: .headers)
        content = try container.decode(HAR.Content.self, forKey: .content)
        redirectURL = try container.decode(String.self, forKey: .redirectURL)
        headersSize = try container.decodeIfPresent(Int.self, forKey: .headersSize) ?? -1
        bodySize = try container.decodeIfPresent(Int.self, forKey: .bodySize) ?? -1
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
    }
}

extension HAR.Response {
    /// cookies property computed from headers.
    public var computedCookies: [HAR.Cookie] {
        var cookies: [HAR.Cookie] = []
        for header in headers {
            if header.name.lowercased() == "set-cookie" {
                cookies.append(HAR.Cookie(fromSetCookieHeader: header.value))
            }
        }
        return cookies
    }

    /// Computed `headerSize`.
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
}

extension HTTPURLResponse {
    public convenience init(url: URL, response: HAR.Response) {
        let headerFields = response.headers.reduce(into: [:]) { $0[$1.name] = $1.value }

        /// - Remark: initializer doesn't appear to have any failure cases
        self.init(
            url: url,
            statusCode: response.status,
            httpVersion: response.httpVersion,
            headerFields: headerFields)!
    }
}

extension HAR.Response {
    init(response: HTTPURLResponse, data: Data?) {
        status = response.statusCode
        statusText = HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
            .capitalized
        headers = HAR.Headers(response.allHeaderFields)

        if let data = data {
            content = HAR.Content(decoding: data, mimeType: response.mimeType)
        } else {
            content = HAR.Content()
        }

        cookies = computedCookies
        headersSize = computedHeadersSize
    }
}

// MARK: - Cookies

extension HAR.Cookie: Equatable {}

extension HAR.Cookie: Hashable {}

extension HAR.Cookie: Codable {}

/// Parse cookie style attribute pairs seperated by `;` and `=`
private func parseCookieAttributes(_ string: String) -> [(key: String, value: String?)] {
    string.split(separator: ";").compactMap {
        let parts = $0.split(separator: "=", maxSplits: 1)
        let key = String(parts[0])
        let value = parts.count > 1 ? String(parts[1]) : nil
        return (
            key.trimmingCharacters(in: .whitespaces),
            value?.trimmingCharacters(in: .whitespaces))
    }
}

extension HAR.Cookie {
    init(fromSetCookieHeader header: String) {
        var attributeValues = parseCookieAttributes(header)

        let (name, value) = attributeValues.removeFirst()
        self.name = name
        self.value = value ?? ""

        secure = false
        httpOnly = false

        for (key, value) in attributeValues {
            switch key.lowercased() {
            case "expires":
                if let value = value {
                    expires = parseExpires(value)
                }
            case "domain":
                domain = value
            case "path":
                path = value
            case "secure":
                secure = true
            case "httponly":
                httpOnly = true
            case "samesite":
                sameSite = value
            default:
                continue
            }
        }
    }

    // Tue, 18 Jan 2022 23:07:07 GMT
    private static let expiresDateFormats = [
        "EEE',' dd MMM yyyy HH:mm:ss 'GMT'",
        "EEE',' dd'-'MMM'-'yy HH:mm:ss 'GMT'",
        "EEE',' dd'-'MMM'-'yyyy HH:mm:ss 'GMT'",
    ]

    private func parseExpires(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")

        for dateFormat in Self.expiresDateFormats {
            formatter.dateFormat = dateFormat
            if let date = formatter.date(from: string) {
                return date
            }
        }

        return nil
    }
}

extension HAR.Cookies {
    init(fromCookieHeader header: String) {
        self = parseCookieAttributes(header).map {
            HAR.Cookie(name: $0.key, value: $0.value ?? "")
        }
    }
}

// MARK: - Headers

extension HAR.Header: Equatable {}

extension HAR.Header: Hashable {}

extension HAR.Header: CustomStringConvertible {
    /// A human-readable description for the data.
    public var description: String {
        "\(name): \(value)"
    }
}

extension HAR.Header: CustomDebugStringConvertible {
    /// A human-readable debug description for the data.
    public var debugDescription: String {
        "HAR.Header { \(description) }"
    }
}

extension HAR.Header: Codable {}

extension HAR.Headers {
    init(_ fields: [AnyHashable: Any]) {
        self = fields.compactMap {
            if let name = $0.key as? String, let value = $0.value as? String {
                return HAR.Header(name: name, value: value)
            } else {
                return nil
            }
        }
    }
}

// MARK: - QueryString

extension HAR.QueryString: Equatable {}

extension HAR.QueryString: Hashable {}

extension HAR.QueryString: CustomStringConvertible {
    /// A human-readable description for the data.
    public var description: String {
        "\(name)=\(value)"
    }
}

extension HAR.QueryString: CustomDebugStringConvertible {
    /// A human-readable debug description for the data.
    public var debugDescription: String {
        "HAR.QueryString { \(description) }"
    }
}

extension HAR.QueryString: Codable {}

extension HAR.QueryString {
    init(_ queryItem: URLQueryItem) {
        name = queryItem.name
        value = queryItem.value?.replacingOccurrences(of: "+", with: " ") ?? ""
    }
}

// MARK: - PostData

extension HAR.PostData: Equatable {}

extension HAR.PostData: Hashable {}

extension HAR.PostData: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Self.CodingKeys.self)

        mimeType = try container.decodeIfPresent(String.self, forKey: .mimeType) ?? ""
        params = try container.decodeIfPresent([HAR.Param].self, forKey: .params) ?? []
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
    }
}

extension HAR.PostData {
    /// Create HAR PostData from plain text.
    init(parsingText text: String, mimeType: String?) {
        self.text = text

        self.mimeType = "application/octet-stream"
        if let mimeType = mimeType {
            self.mimeType = mimeType
        }

        params = []
        if self.mimeType.hasPrefix("application/x-www-form-urlencoded") {
            params = parseFormUrlEncoded(self.text)
        }
    }

    internal func parseFormUrlEncoded(_ str: String) -> [HAR.Param] {
        var components = URLComponents()
        components.query = str
        return components.queryItems?.map {
            return HAR.Param(
                name: $0.name,
                value: $0.value?
                    .replacingOccurrences(of: "+", with: "%20")
                    .removingPercentEncoding ?? "")
        } ?? []
    }

    /// Create HAR PostData from data.
    init?(parsingData data: Data, mimeType: String?) {
        guard let text = String(bytes: data, encoding: .utf8) else {
            return nil
        }
        self.init(parsingText: text, mimeType: mimeType)
    }

    var data: Data? {
        Data(text.utf8)
    }
}

// MARK: - Params

extension HAR.Param: Equatable {}

extension HAR.Param: Hashable {}

extension HAR.Param: CustomStringConvertible {
    /// A human-readable description for the data.
    public var description: String {
        var str = "\(name)"

        if let fileName = fileName {
            str += "=@\(fileName)"

            if let contentType = contentType {
                str += ";type=\(contentType)"
            }
        } else if let value = value {
            str += "=\(value)"
        }

        return str
    }
}

extension HAR.Param: CustomDebugStringConvertible {
    /// A human-readable debug description for the data.
    public var debugDescription: String {
        "HAR.Param { \(description) }"
    }
}

extension HAR.Param: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Self.CodingKeys.self)

        /// Override synthesised decoder to handle empty `name`.
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""

        value = try container.decodeIfPresent(String.self, forKey: .value)
        fileName = try container.decodeIfPresent(String.self, forKey: .fileName)
        contentType = try container.decodeIfPresent(String.self, forKey: .contentType)
    }
}

// MARK: - Content

extension HAR.Content: Equatable {}

extension HAR.Content: Hashable {}

extension HAR.Content: Codable {}

extension HAR.Content {
    public init() {
        size = 0
        mimeType = "application/octet-stream"
    }

    /// Create HAR Content from string.
    public init(text: String, encoding: String? = nil, mimeType: String?) {
        self.init()

        if let mimeType = mimeType {
            self.mimeType = mimeType
        }

        self.encoding = encoding
        self.text = text

        if let data = data {
            size = data.count
        }
    }

    /// Create HAR Content decoding HTTP Body Data.
    public init(decoding data: Data, mimeType: String?) {
        self.init()

        if let mimeType = mimeType {
            self.mimeType = mimeType
        }

        size = data.count

        if let text = String(bytes: data, encoding: .utf8) {
            self.text = text
        } else {
            text = data.base64EncodedString()
            encoding = "base64"
        }
    }

    /// Get content body as Data. May return nil if text is encoded improperly.
    public var data: Data? {
        guard let text = text else { return nil }
        switch encoding {
        case "base64":
            return Data(base64Encoded: text)
        default:
            return Data(text.utf8)
        }
    }
}

// MARK: - Cache

extension HAR.Cache: Equatable {}

extension HAR.Cache: Hashable {}

extension HAR.Cache: Codable {}

extension HAR.CacheEntry: Equatable {}

extension HAR.CacheEntry: Hashable {}

extension HAR.CacheEntry: Codable {}

// MARK: - Timings

extension HAR.Timing: Equatable {}

extension HAR.Timing: Hashable {}

extension HAR.Timing: Codable {}

extension HAR.Timing {
    /// Compute total request time.
    ///
    /// The time value for the request must be equal to the sum of the timings supplied
    /// in this section (excluding any -1 values).
    public var total: Double {
        [blocked, dns, connect, send, wait, receive]
            .map { $0 ?? -1 }
            .filter { $0 != -1 }
            .reduce(0, +)
    }
}

// MARK: - Other

extension HAR.Entry {
    public static func record(request: URLRequest, completionHandler: @escaping (Result<Self, Error>) -> Void) {
        var timings = HAR.Timing(send: 0, wait: 0, receive: 0)
        let start = DispatchTime.now()

        let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
            timings.receive = Double(
                DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds
            ) / 1000000

            if let response = response as? HTTPURLResponse {
                let entry = Self(
                    time: timings.total,
                    request: HAR.Request(request: request),
                    response: HAR.Response(response: response, data: data),
                    timings: timings)
                completionHandler(.success(entry))
            } else if let error = error {
                completionHandler(.failure(error))
            }
        }

        dataTask.resume()
    }

    public static func record(request: URLRequest) throws -> Self {
        try syncResult { record(request: request, completionHandler: $0) }
    }
}

extension HAR {
    public static func record(request: URLRequest, completionHandler: @escaping (Result<Self, Error>) -> Void) {
        Self.Entry.record(
            request: request,
            completionHandler: {
                completionHandler($0.map { Self(log: Self.Log(entries: [$0])) })
        })
    }

    public static func record(request: URLRequest) throws -> Self {
        try syncResult { Self.record(request: request, completionHandler: $0) }
    }
}

internal func syncResult<T>(
    _ asyncHandler: (@escaping (Result<T, Error>) -> Void) -> Void
) throws -> T {
    let semaphore = DispatchSemaphore(value: 0)
    var result: Result<T, Error>?

    asyncHandler { (asyncResult: Result<T, Error>) in
        result = asyncResult
        semaphore.signal()
    }

    _ = semaphore.wait(timeout: .distantFuture)
    return try result!.get()
}
