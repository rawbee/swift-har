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

/// HTTP Archive
/// - Version: 1.2
///
/// http://www.softwareishard.com/blog/har-12-spec/
public struct HAR: Equatable, Hashable, Codable, HAR.Redactable {
    // MARK: Properties

    /// Log data root.
    public var log: Log

    // MARK: Initializers

    /// Create HAR.
    public init(log: Log) {
        self.log = log
    }

    // MARK: Encoding and Decoding

    /// Creates a `HAR` from the contents of a file URL.
    ///
    /// - Parameter url: Path to `.har` file.
    public init(contentsOf url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    /// Writes the ecoded HAR to a location.
    public func write(to url: URL, options: Data.WritingOptions = []) throws {
        try encoded().write(to: url, options: options)
    }

    /// Initialize ISO 8601 date formatter.
    ///
    /// Uses the format `YYYY-MM-DDThh:mm:ss.sTZD` to return a date such as
    private static let jsonDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSZZZZZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    /// Creates a `HAR` from JSON `Data`.
    ///
    /// - Parameter data: UTF-8 JSON data.
    public init(data: Data) throws {
        let decoder = JSONDecoder()

        decoder.dateDecodingStrategy = .custom { (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)

            if let date = Self.jsonDateFormatter.date(from: dateStr) {
                return date
            }

            throw Swift.DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "invalid date: \(dateStr)"
            )
        }

        self = try decoder.decode(Self.self, from: data)
    }

    /// Returns a HAR encoded as JSON `Data`.
    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .formatted(Self.jsonDateFormatter)
        return try encoder.encode(self)
    }

    // MARK: Redacting sensitive data

    /// Replace entry request/response headers with placeholder text.
    public mutating func redact(_ pattern: NSRegularExpression, placeholder: String) {
        log.redact(pattern, placeholder: placeholder)
    }

    // MARK: Structures

    /// This object represents the root of exported data.
    ///
    /// There is one `Page` object for every exported web page and one `Entry` object
    /// for every HTTP request. In case when an HTTP trace tool isn't able to group
    /// requests by a page, the `pages` object is empty and individual requests doesn't
    /// have a parent page.
    public struct Log: Equatable, Hashable, Codable, Redactable {
        // MARK: Properties

        /// Version number of the format. If empty, string "1.1" is assumed by default.
        public var version: String

        /// Name and version info of the log creator application.
        public var creator: Creator

        /// Name and version info of used browser.
        public var browser: Browser?

        /// List of all exported (tracked) pages. Leave out this field if the
        /// application does not support grouping by pages.
        public var pages: Pages?

        /// List of all exported (tracked) requests.
        public var entries: Entries

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?

        // MARK: Computed Properties

        /// Access log's first entry.
        ///
        /// - Invariant: Log's must have at least one entry to be valid.
        /// However, a log maybe empty on initial construction.
        public var firstEntry: Entry {
            guard let entry = entries.first else {
                preconditionFailure("HAR.Log has no entries")
            }
            return entry
        }

        // MARK: Initializers

        /// Create log.
        public init(
            version: String = "1.2", creator: Creator = Creator.default, browser: Browser? = nil,
            pages: Pages? = nil, entries: Entries = [], comment: String? = nil
        ) {
            self.version = version
            self.creator = creator
            self.browser = browser
            self.pages = pages
            self.entries = entries
            self.comment = comment
        }

        // MARK: Redacting sensitive data

        /// Replace entry request/response headers with placeholder text.
        public mutating func redact(_ pattern: NSRegularExpression, placeholder: String) {
            entries = entries.map { $0.redacting(pattern, placeholder: placeholder) }
        }
    }

    /// This object represents the log creator application.
    public struct Creator: Equatable, Hashable, Codable, CustomStringConvertible,
        CustomDebugStringConvertible {
        // MARK: Static Properties

        /// Creator info used when this library creates a new HAR log.
        public static let `default` = Creator(name: "SwiftHAR", version: "0.1.0")

        // MARK: Properties

        /// Name of the application/browser used to export the log.
        public var name: String

        /// Version of the application/browser used to export the log.
        public var version: String

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?

        // MARK: Initializers

        /// Create creator.
        public init(name: String, version: String, comment: String? = nil) {
            self.name = name
            self.version = version
            self.comment = comment
        }

        // MARK: Describing Creators

        /// A human-readable description for the data.
        public var description: String {
            "\(name)/\(version)"
        }

        /// A human-readable debug description for the data.
        public var debugDescription: String {
            "HAR.Browser { \(description) }"
        }
    }

    /// This object represents the web browser used.
    public struct Browser: Equatable, Hashable, Codable, CustomStringConvertible,
        CustomDebugStringConvertible {
        // MARK: Properties

        /// Name of the application/browser used to export the log.
        public var name: String

        /// Version of the application/browser used to export the log.
        public var version: String

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?

        // MARK: Initializers

        /// Create browser.
        public init(name: String, version: String, comment: String? = nil) {
            self.name = name
            self.version = version
            self.comment = comment
        }

        // MARK: Describing Browsers

        /// A human-readable description for the data.
        public var description: String {
            "\(name)/\(version)"
        }

        /// A human-readable debug description for the data.
        public var debugDescription: String {
            "HAR.Browser { \(description) }"
        }
    }

    /// This object represents list of exported pages.
    public struct Page: Equatable, Hashable, Codable, CustomStringConvertible,
        CustomDebugStringConvertible {
        // MARK: Properties

        /// Date and time stamp for the beginning of the page load.
        public var startedDateTime: Date

        /// Unique identifier of a page within the `Log`. Entries use it to refer the
        /// parent page.
        public var id: String

        /// Page title.
        public var title: String

        /// Detailed timing info about page load.
        public var pageTimings: PageTiming

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?

        // MARK: Initializers

        /// Create page.
        public init(
            startedDateTime: Date, id: String, title: String = "", pageTimings: PageTiming = PageTiming(),
            comment: String? = nil
        ) {
            self.startedDateTime = startedDateTime
            self.id = id
            self.title = title
            self.pageTimings = pageTimings
            self.comment = comment
        }

        // MARK: Encoding and Decoding

        /// Create Page from Decoder.
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Self.CodingKeys.self)

            startedDateTime = try container.decode(Date.self, forKey: .startedDateTime)
            id = try container.decode(String.self, forKey: .id)
            title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
            self.pageTimings = try container.decode(PageTiming.self, forKey: .pageTimings)
            self.comment = try container.decodeIfPresent(String.self, forKey: .comment)
        }

        // MARK: Describing Pages

        /// Date formatter for Page description.
        private static let startedDateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d/yyyy, h:mm:ss a"
            return formatter
        }()

        /// A human-readable description for the data.
        public var description: String {
            var strs: [String] = []

            if let onLoad = pageTimings.onLoad {
                strs.append("\(onLoad.rounded())ms")
            }

            strs.append(Self.startedDateFormatter.string(from: startedDateTime))
            strs.append(title)

            return strs.joined(separator: "  ")
        }

        /// A human-readable debug description for the data.
        public var debugDescription: String {
            "HAR.Page { \(description) }"
        }
    }

    /// Array of Page objects.
    public typealias Pages = [Page]

    /// This object describes timings for various events (states) fired during the page
    /// load. All times are specified in milliseconds. If a time info is not available
    /// appropriate field is set to -1.
    ///
    /// Depending on the browser, onContentLoad property represents `DOMContentLoad`
    /// event or `document.readyState == interactive`.
    public struct PageTiming: Equatable, Hashable, Codable, CustomStringConvertible,
        CustomDebugStringConvertible {
        // MARK: Properties

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

        // MARK: Initializers

        /// Create page timing.
        public init(onContentLoad: Double = -1, onLoad: Double = -1, comment: String? = nil) {
            self.onContentLoad = onContentLoad
            self.onLoad = onLoad
            self.comment = comment
        }

        // MARK: Describing Page Timings

        /// A human-readable description for the data.
        public var description: String {
            "onContentLoad: \(onContentLoad ?? -1), onLoad: \(onLoad ?? -1)"
        }

        /// A human-readable debug description for the data.
        public var debugDescription: String {
            "HAR.PageTiming { \(description) }"
        }
    }

    /// This object represents an array with all exported HTTP requests. Sorting entries
    /// by `startedDateTime` (starting from the oldest) is preferred way how to export
    /// data since it can make importing faster. However the reader application should
    /// always make sure the array is sorted (if required for the import).
    public struct Entry: Equatable, Hashable, Codable, Redactable {
        // MARK: Properties

        /// Reference to the parent page. Leave out this field if the application does
        /// not support grouping by pages.
        public var pageref: String?

        /// Date and time stamp of the request start.
        public var startedDateTime: Date

        /// Total elapsed time of the request in milliseconds. This is the sum of all
        /// timings available in the timings object (i.e. not including -1 values) .
        ///
        /// - Invariant: The time value for the request must be equal to the sum of the
        /// timings supplied in this section (excluding any -1 values).
        public var time: Double

        /// Detailed info about the request.
        public var request: Request

        /// Detailed info about the response.
        public var response: Response

        /// Info about cache usage.
        public var cache: Cache

        /// Detailed timing info about request/response round trip.
        public var timings: Timing

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

        // MARK: Computed Properties

        /// Computed `time` from timings.
        public var computedTime: Double {
            timings.total
        }

        // MARK: Initializers

        /// Create entry.
        public init(
            pageref: String? = nil, startedDateTime: Date = Date(), time: Double = 0,
            request: Request, response: Response, cache: Cache = Cache(),
            timings: Timing = Timing(), serverIPAddress: String? = nil, connection: String? = nil,
            comment: String? = nil
        ) {
            self.pageref = pageref
            self.startedDateTime = startedDateTime
            self.time = time
            self.request = request
            self.response = response
            self.cache = cache
            self.timings = timings
            self.serverIPAddress = serverIPAddress
            self.connection = connection
            self.comment = comment
        }

        // MARK: Redacting sensitive data

        /// Replace request/response headers with placeholder text.
        public mutating func redact(_ pattern: NSRegularExpression, placeholder: String) {
            request.redact(pattern, placeholder: placeholder)
            response.redact(pattern, placeholder: placeholder)
        }
    }

    /// Array of Entry objects.
    public typealias Entries = [Entry]

    /// This object contains detailed info about performed request.
    public struct Request: Equatable, Hashable, Codable, CustomStringConvertible,
        CustomDebugStringConvertible, Redactable {
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
            let container = try decoder.container(keyedBy: Self.CodingKeys.self)

            method = try container.decode(String.self, forKey: .method)
            url = try container.decode(URL.self, forKey: .url)
            httpVersion = try container.decodeIfPresent(String.self, forKey: .httpVersion)
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

        /// Replace matched request headers with placeholder text.
        public mutating func redact(_ pattern: NSRegularExpression, placeholder: String) {
            headers.redact(pattern, placeholder: placeholder)

            if headers.value(forName: "Cookie") == placeholder {
                cookies = cookies.map { $0.redacting(placeholder: placeholder) }
            }
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

    /// This object contains detailed info about the response.
    public struct Response: Equatable, Hashable, Codable, CustomStringConvertible,
        CustomDebugStringConvertible, Redactable {
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
            cookies: Cookies? = nil, headers: Headers = [], content: Content = Content(),
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
            let container = try decoder.container(keyedBy: Self.CodingKeys.self)

            status = try container.decode(Int.self, forKey: .status)
            statusText = try container.decode(String.self, forKey: .statusText)
            httpVersion = try container.decodeIfPresent(String.self, forKey: .httpVersion)
                ?? "HTTP/1.1"
            self.cookies = try container.decode(Cookies.self, forKey: .cookies)
            self.headers = try container.decode(Headers.self, forKey: .headers)
            self.content = try container.decode(Content.self, forKey: .content)
            self.redirectURL = try container.decode(String.self, forKey: .redirectURL)
            self.headersSize = try container.decodeIfPresent(Int.self, forKey: .headersSize) ?? -1
            self.bodySize = try container.decodeIfPresent(Int.self, forKey: .bodySize) ?? -1
            self.comment = try container.decodeIfPresent(String.self, forKey: .comment)
        }

        // MARK: Redacting sensitive data

        /// Replace matched response headers with placeholder text.
        public mutating func redact(_ pattern: NSRegularExpression, placeholder: String) {
            headers.redact(pattern, placeholder: placeholder)

            if headers.value(forName: "Set-Cookie") == placeholder {
                cookies = cookies.map { $0.redacting(placeholder: placeholder) }
            }
        }

        // MARK: Describing Responses

        /// A human-readable description for the data.
        public var description: String {
            var strs: [String] = []

            strs.append("\(status) \(statusText)")
            strs.append(content.mimeType)

            let formatter = ByteCountFormatter()
            formatter.countStyle = .binary
            strs.append(formatter.string(fromByteCount: Int64(bodySize)))

            return strs.joined(separator: "  ")
        }

        /// A human-readable debug description for the data.
        public var debugDescription: String {
            "HAR.Response { \(description) }"
        }
    }

    /// This object contains list of all cookies (used in `Request` and `Response`
    /// objects).
    public struct Cookie: Equatable, Hashable, Codable {
        // MARK: Properties

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

        // MARK: Initializers

        /// Create cookie.
        public init(
            name: String, value: String, path: String? = nil, domain: String? = nil, expires: Date? = nil,
            httpOnly: Bool? = nil, secure: Bool? = nil, comment: String? = nil, sameSite: String? = nil
        ) {
            self.name = name
            self.value = value
            self.path = path
            self.domain = domain
            self.expires = expires
            self.httpOnly = httpOnly
            self.secure = secure
            self.comment = comment
            self.sameSite = sameSite
        }

        /// Create Cookie from HTTP Response "Set-Cookie" header value.
        internal init(fromSetCookieHeader header: String) {
            var attributeValues = Self.parseCookieAttributes(header)

            let (name, value) = attributeValues.removeFirst()
            self.name = name
            self.value = value ?? ""

            self.secure = false
            self.httpOnly = false

            for (key, value) in attributeValues {
                switch key.lowercased() {
                case "expires":
                    if let value = value {
                        self.expires = parseExpires(value)
                    }
                case "domain":
                    self.domain = value
                case "path":
                    self.path = value
                case "secure":
                    self.secure = true
                case "httponly":
                    self.httpOnly = true
                case "samesite":
                    self.sameSite = value
                default:
                    continue
                }
            }
        }

        /// Date Formatter to attempt parsing "Expires" strings.
        /// "Tue, 18 Jan 2022 23:07:07 GMT"
        private static let expiresDateFormats = [
            "EEE',' dd MMM yyyy HH:mm:ss 'GMT'",
            "EEE',' dd'-'MMM'-'yy HH:mm:ss 'GMT'",
            "EEE',' dd'-'MMM'-'yyyy HH:mm:ss 'GMT'",
        ]

        /// Parse Set-Cookie expires strings.
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

        // MARK: Describing Requests

        /// Return cookie replacing value with placeholder.
        internal func redacting(placeholder: String) -> Self {
            var copy = self
            copy.value = placeholder
            return copy
        }

        // MARK: Static Methods

        /// Parse cookie style attribute pairs seperated by `;` and `=`
        internal static func parseCookieAttributes(_ string: String) -> [(key: String, value: String?)] {
            string.split(separator: ";").compactMap {
                let parts = $0.split(separator: "=", maxSplits: 1)
                let key = String(parts[0])
                let value = parts.count > 1 ? String(parts[1]) : nil
                return (
                    key.trimmingCharacters(in: .whitespaces),
                    value?.trimmingCharacters(in: .whitespaces)
                )
            }
        }
    }

    /// Array of Cookie objects.
    public typealias Cookies = [Cookie]

    /// This object contains list of all headers (used in `Request` and `Response`
    /// objects).
    public struct Header: Equatable, Hashable, Codable, CustomStringConvertible,
        CustomDebugStringConvertible, Redactable {
        // MARK: Properties

        /// The header name.
        public var name: String

        /// The header value.
        public var value: String

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?

        // MARK: Initializers

        /// Create header.
        public init(name: String, value: String, comment: String? = nil) {
            self.name = name
            self.value = value
            self.comment = comment
        }

        // MARK: Comparing Headers

        /// Returns a Boolean value indicating whether two headers are equal.
        ///
        /// Header names are case-insensitive.
        public static func ==(lhs: Self, rhs: Self) -> Bool {
            lhs.name.caseInsensitiveCompare(rhs.name) == .orderedSame && lhs.value == rhs.value
                && lhs.comment == rhs.comment
        }

        /// Test if header name matches case-insensitive name.
        public func isNamed(_ name: String) -> Bool {
            self.name.caseInsensitiveCompare(name) == .orderedSame
        }

        /// Test if header name matches Regular Expression.
        public func isNamed(_ pattern: NSRegularExpression) -> Bool {
            let range = NSRange(name.startIndex ..< name.endIndex, in: name)
            return pattern.firstMatch(in: name, options: [], range: range) != nil
        }

        /// Hashes the lower case name of the header by feeding them into the given hasher.
        public func hash(into hasher: inout Hasher) {
            hasher.combine(name.lowercased())
        }

        // MARK: Describing Requests

        /// Replace value with placeholder text if name matches pattern.
        public mutating func redact(_ pattern: NSRegularExpression, placeholder: String) {
            if isNamed(pattern) {
                value = placeholder
            }
        }

        // MARK: Describing Headers

        /// A human-readable description for the data.
        public var description: String {
            "\(name): \(value)"
        }

        /// A human-readable debug description for the data.
        public var debugDescription: String {
            "HAR.Header { \(description) }"
        }
    }

    /// Array of Header objects.
    public typealias Headers = [Header]

    /// This object contains list of all parameters & values parsed from a query string,
    /// if any (embedded in `Request` object).
    public struct QueryString: Equatable, Hashable, Codable, CustomStringConvertible,
        CustomDebugStringConvertible {
        // MARK: Properties

        /// The query parameter name.
        public var name: String

        /// The query parameter value.
        public var value: String

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?

        // MARK: Initializers

        /// Create query string.
        public init(name: String, value: String, comment: String? = nil) {
            self.name = name
            self.value = value
            self.comment = comment
        }

        /// Create QueryString item from `URLQueryItem`.
        internal init(_ queryItem: URLQueryItem) {
            self.name = queryItem.name
            self.value = queryItem.value?.replacingOccurrences(of: "+", with: " ") ?? ""
        }

        // MARK: Describing Query Strings

        /// A human-readable description for the data.
        public var description: String {
            "\(name)=\(value)"
        }

        /// A human-readable debug description for the data.
        public var debugDescription: String {
            "HAR.QueryString { \(description) }"
        }
    }

    /// Array of QueryString objects.
    public typealias QueryStrings = [QueryString]

    /// This object describes posted data, if any (embedded in `Request` object).
    public struct PostData: Equatable, Hashable, Codable {
        // MARK: Properties

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

        // MARK: Computed Properties

        /// Get text as UTF8 Data.
        public var data: Data {
            Data(text.utf8)
        }

        /// Get bytesize of text.
        public var size: Int {
            data.count
        }

        // MARK: Initializers

        /// Create post data.
        public init(mimeType: String, params: Params, text: String, comment: String? = nil) {
            self.mimeType = mimeType
            self.params = params
            self.text = text
            self.comment = comment
        }

        /// Create HAR PostData from plain text.
        public init(parsingText text: String, mimeType: String?) {
            self.text = text

            self.mimeType = "application/octet-stream"
            if let mimeType = mimeType {
                self.mimeType = mimeType
            }

            self.params = []
            if self.mimeType.hasPrefix("application/x-www-form-urlencoded") {
                self.params = parseFormUrlEncoded(self.text)
            }
        }

        private func parseFormUrlEncoded(_ str: String) -> Params {
            var components = URLComponents()
            components.query = str
            return components.queryItems?.map {
                return Param(
                    name: $0.name,
                    value:
                    $0.value?
                        .replacingOccurrences(of: "+", with: "%20")
                        .removingPercentEncoding ?? ""
                )
            } ?? []
        }

        /// Create HAR PostData from data.
        public init?(parsingData data: Data, mimeType: String?) {
            guard let text = String(bytes: data, encoding: .utf8) else {
                return nil
            }
            self.init(parsingText: text, mimeType: mimeType)
        }

        // MARK: Encoding and Decoding

        /// Create PostData from Decoder.
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Self.CodingKeys.self)

            mimeType = try container.decodeIfPresent(String.self, forKey: .mimeType) ?? ""
            self.params = try container.decodeIfPresent(Params.self, forKey: .params) ?? []
            self.text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
            self.comment = try container.decodeIfPresent(String.self, forKey: .comment)
        }
    }

    /// List of posted parameters, if any (embedded in `PostData` object).
    public struct Param: Equatable, Hashable, Codable, CustomStringConvertible,
        CustomDebugStringConvertible {
        // MARK: Properties

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

        // MARK: Initializers

        /// Create param.
        public init(
            name: String, value: String? = nil, fileName: String? = nil, contentType: String? = nil,
            comment: String? = nil
        ) {
            self.name = name
            self.value = value
            self.fileName = fileName
            self.contentType = contentType
            self.comment = comment
        }

        // MARK: Encoding and Decoding

        /// Create Param from Decoder.
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Self.CodingKeys.self)

            /// Override synthesised decoder to handle empty `name`.
            name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""

            self.value = try container.decodeIfPresent(String.self, forKey: .value)
            self.fileName = try container.decodeIfPresent(String.self, forKey: .fileName)
            self.contentType = try container.decodeIfPresent(String.self, forKey: .contentType)
        }

        // MARK: Describing Params

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

        /// A human-readable debug description for the data.
        public var debugDescription: String {
            "HAR.Param { \(description) }"
        }
    }

    /// Array of Param objects.
    public typealias Params = [Param]

    /// This object describes details about response content (embedded in `Response`
    /// object).
    public struct Content: Equatable, Hashable, Codable {
        // MARK: Properties

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

        // MARK: Computed Properties

        /// Get content body as Data. May return empty Data if text is encoded improperly.
        public var data: Data {
            guard let text = text else { return Data(count: 0) }
            switch encoding {
            case "base64":
                return Data(base64Encoded: text) ?? Data(count: 0)
            default:
                return Data(text.utf8)
            }
        }

        // MARK: Initializers

        /// Create content.
        public init(
            size: Int, compression: Int? = nil, mimeType: String, text: String? = nil,
            encoding: String? = nil, comment: String? = nil
        ) {
            self.size = size
            self.compression = compression
            self.mimeType = mimeType
            self.text = text
            self.encoding = encoding
            self.comment = comment
        }

        /// Create empty unknown response body content.
        public init() {
            self.size = 0
            self.mimeType = "application/octet-stream"
        }

        /// Create HAR Content from string.
        public init(text: String, encoding: String? = nil, mimeType: String?) {
            self.init()

            if let mimeType = mimeType {
                self.mimeType = mimeType
            }

            self.encoding = encoding
            self.text = text
            self.size = data.count
        }

        /// Create HAR Content decoding HTTP Body Data.
        public init(decoding data: Data, mimeType: String?) {
            self.init()

            if let mimeType = mimeType {
                self.mimeType = mimeType
            }

            self.size = data.count

            if let text = String(bytes: data, encoding: .utf8) {
                self.text = text
            } else {
                self.text = data.base64EncodedString()
                self.encoding = "base64"
            }
        }
    }

    /// This objects contains info about a request coming from browser cache.
    public struct Cache: Equatable, Hashable, Codable {
        // MARK: Properties

        /// State of a cache entry before the request. Leave out this field if the
        /// information is not available.
        public var beforeRequest: CacheEntry?

        /// State of a cache entry after the request. Leave out this field if the
        /// information is not available.
        public var afterRequest: CacheEntry?

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?

        // MARK: Initializers

        /// Create cache.
        public init() {}

        /// Create cache.
        public init(
            beforeRequest: CacheEntry? = nil, afterRequest: CacheEntry? = nil,
            comment: String? = nil
        ) {
            self.beforeRequest = beforeRequest
            self.afterRequest = afterRequest
            self.comment = comment
        }
    }

    /// This objects contains cache entry state for the request.
    public struct CacheEntry: Equatable, Hashable, Codable {
        // MARK: Properties

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

        // MARK: Initializers

        /// Create cache entry.
        public init(
            expires: Date? = nil, lastAccess: Date, eTag: String, hitCount: Int, comment: String? = nil
        ) {
            self.expires = expires
            self.lastAccess = lastAccess
            self.eTag = eTag
            self.hitCount = hitCount
            self.comment = comment
        }
    }

    /// This object describes various phases within request-response round trip. All
    /// times are specified in milliseconds.
    public struct Timing: Equatable, Hashable, Codable, CustomStringConvertible,
        CustomDebugStringConvertible {
        // MARK: Properties

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

        // MARK: Computed Properties

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

        // MARK: Initializers

        /// Create timing.
        public init(
            blocked: Double? = -1, dns: Double? = -1, connect: Double? = -1, send: Double = -1,
            wait: Double = -1, receive: Double = -1, ssl: Double? = -1, comment: String? = nil
        ) {
            self.blocked = blocked
            self.dns = dns
            self.connect = connect
            self.send = send
            self.wait = wait
            self.receive = receive
            self.ssl = ssl
            self.comment = comment
        }

        // MARK: Describing Timings

        /// A human-readable description for the data.
        public var description: String {
            """
            Blocked: \(blocked ?? -1)ms
            DNS: \(dns ?? -1)ms
            SSL/TLS: \(ssl ?? -1)ms
            Connect: \(connect ?? -1)ms
            Send: \(send)ms
            Wait: \(wait)ms
            Receive: \(receive)ms
            """
        }

        /// A human-readable debug description for the data.
        public var debugDescription: String {
            "HAR.Timing {\n\(description)\n}"
        }
    }

    public struct CurlCommand: CustomStringConvertible {
        var url: URL
        var method: String
        var headers: [(name: String, value: String)]

        init(url: URL, method: String = "GET", headers: [(name: String, value: String)] = []) {
            self.url = url
            self.method = method
            self.headers = headers
        }

        init(request: Request) {
            self.url = request.url
            self.method = request.method
            self.headers = request.headers.map { (name: $0.name, value: $0.value) }
        }

        public var description: String {
            var lines: [String] = []

            lines.append("curl '\(url)'")

            if method != "GET" {
                lines.append("--request \(method)")
            }

            for (name, value) in headers {
                lines.append("--header '\(name): \(value)'")
            }

            return lines.joined(separator: " \\\n  ")
        }
    }

    public typealias Redactable = __HARRedactable
}

extension HAR.Cookies {
    // MARK: Initializers

    /// Create Cookies array from HTTP Request "Cookie:" header value.
    internal init(fromCookieHeader header: String) {
        self = HAR.Cookie.parseCookieAttributes(header).map {
            HAR.Cookie(name: $0.key, value: $0.value ?? "")
        }
    }
}

extension HAR.Headers: HAR.Redactable {
    // MARK: Computed Properties

    public var headersAsDictionary: [String: String] {
        reduce(into: [:]) { result, header in
            if result[header.name] == nil {
                result[header.name] = header.value
            } else {
                result[header.name]! += (", " + header.value)
            }
        }
    }

    // MARK: Instance Methods

    /// Find all header values for name.
    ///
    /// Header names are case-insensitive.
    ///
    /// - Parameter name: The HTTP Header name.
    public func values(forName name: String) -> [String] {
        filter { $0.isNamed(name) }.map { $0.value }
    }

    /// Find first header value for name.
    ///
    /// Header names are case-insensitive.
    ///
    /// - Parameter name: The HTTP Header name.
    public func value(forName name: String) -> String? {
        values(forName: name).first
    }

    // MARK: Redacting sensitive data

    /// Return new headers replacing matched headers with placeholder text.
    public func redacting(_ pattern: NSRegularExpression, placeholder: String) -> Self {
        map { $0.redacting(pattern, placeholder: placeholder) }
    }
}

public protocol __HARRedactable {
    /// Replace matched data with placeholder text.
    mutating func redact(_ pattern: NSRegularExpression, placeholder: String)

    /// Return new redacted data with placeholder text.
    func redacting(_ pattern: NSRegularExpression, placeholder: String) -> Self
}

extension HAR.Redactable {
    /// Replace matched data with placeholder text.
    public mutating func redact(_ pattern: NSRegularExpression, placeholder: String) {
        self = redacting(pattern, placeholder: placeholder)
    }

    /// Return new redacted data with placeholder text.
    public func redacting(_ pattern: NSRegularExpression, placeholder: String) -> Self {
        var copy = self
        copy.redact(pattern, placeholder: placeholder)
        return copy
    }
}
