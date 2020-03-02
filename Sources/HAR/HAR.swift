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

/// HTTP Archive
/// - Version: 1.2
///
/// http://www.softwareishard.com/blog/har-12-spec/
public struct HAR {
    // MARK: Properties

    /// Log data root.
    public var log: Log

    // MARK: Structures

    /// This object represents the root of exported data.
    ///
    /// There is one `Page` object for every exported web page and one `Entry` object
    /// for every HTTP request. In case when an HTTP trace tool isn't able to group
    /// requests by a page, the `pages` object is empty and individual requests doesn't
    /// have a parent page.
    public struct Log {
        // MARK: Properties

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

    /// This object represents the log creator application.
    public struct Creator {
        // MARK: Static Properties

        /// Creator info used when this library creates a new HAR log.
        public static let defaultCreator = Creator(name: "SwiftHAR", version: "0.1.0")

        // MARK: Properties

        /// Name of the application/browser used to export the log.
        public var name: String

        /// Version of the application/browser used to export the log.
        public var version: String

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    /// This object represents the web browser used.
    public struct Browser {
        // MARK: Properties

        /// Name of the application/browser used to export the log.
        public var name: String

        /// Version of the application/browser used to export the log.
        public var version: String

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    /// This object represents list of exported pages.
    public struct Page {
        // MARK: Properties

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

    /// Array of Page objects.
    public typealias Pages = [Page]

    /// This object describes timings for various events (states) fired during the page
    /// load. All times are specified in milliseconds. If a time info is not available
    /// appropriate field is set to -1.
    ///
    /// Depending on the browser, onContentLoad property represents `DOMContentLoad`
    /// event or `document.readyState == interactive`.
    public struct PageTiming {
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
    }

    /// This object represents an array with all exported HTTP requests. Sorting entries
    /// by `startedDateTime` (starting from the oldest) is preferred way how to export
    /// data since it can make importing faster. However the reader application should
    /// always make sure the array is sorted (if required for the import).
    public struct Entry {
        // MARK: Properties

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
        public var timings: Timing = Timing()

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

    /// Array of Entry objects.
    public typealias Entries = [Entry]

    /// This object contains detailed info about performed request.
    public struct Request {
        // MARK: Properties

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
    }

    /// This object contains detailed info about the response.
    public struct Response {
        // MARK: Properties

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

    /// This object contains list of all cookies (used in `Request` and `Response`
    /// objects).
    public struct Cookie {
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
    }

    /// Array of Cookie objects.
    public typealias Cookies = [Cookie]

    /// This object contains list of all headers (used in `Request` and `Response`
    /// objects).
    public struct Header {
        // MARK: Properties

        /// The header name.
        public var name: String

        /// The header value.
        public var value: String

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    /// Array of Header objects.
    public typealias Headers = [Header]

    /// This object contains list of all parameters & values parsed from a query string,
    /// if any (embedded in `Request` object).
    public struct QueryString {
        // MARK: Properties

        /// The query parameter name.
        public var name: String

        /// The query parameter value.
        public var value: String

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    /// Array of QueryString objects.
    public typealias QueryStrings = [QueryString]

    /// This object describes posted data, if any (embedded in `Request` object).
    public struct PostData {
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
    }

    /// List of posted parameters, if any (embedded in `PostData` object).
    public struct Param {
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
    }

    /// Array of Param objects.
    public typealias Params = [Param]

    /// This object describes details about response content (embedded in `Response`
    /// object).
    public struct Content {
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
    }

    /// This objects contains info about a request coming from browser cache.
    public struct Cache {
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
    }

    /// This objects contains cache entry state for the request.
    public struct CacheEntry {
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
    }

    /// This object describes various phases within request-response round trip. All
    /// times are specified in milliseconds.
    public struct Timing {
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
    }
}

// MARK: - HAR

extension HAR: Equatable {}

extension HAR: Hashable {}

extension HAR: Codable {
    // MARK: Encoding and Decoding

    /// Creates a `HAR` from the contents of a file URL.
    ///
    /// - Parameter url: Path to `.har` file.
    public init(contentsOf url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    /// Writes the ecoded HAR to a location.
    func write(to url: URL, options: Data.WritingOptions = []) throws {
        try encoded().write(to: url, options: options)
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
                debugDescription: "invalid date: \(dateStr)"
            )
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

extension HAR.Log {
    // MARK: Computed Properties

    /// Access log's first entry.
    ///
    /// - Invariant: Log's must have at least one entry to be valid.
    /// However, a log maybe empty on initial construction.
    public var firstEntry: HAR.Entry {
        guard let entry = entries.first else {
            preconditionFailure("HAR.Log has no entries")
        }
        return entry
    }
}

// MARK: - Creator

extension HAR.Creator: Equatable {}

extension HAR.Creator: Hashable {}

extension HAR.Creator: CustomStringConvertible {
    // MARK: Describing Creators

    /// A human-readable description for the data.
    public var description: String {
        "\(name)/\(version)"
    }
}

extension HAR.Creator: CustomDebugStringConvertible {
    // MARK: Describing Creators

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
    // MARK: Describing Browsers

    /// A human-readable description for the data.
    public var description: String {
        "\(name)/\(version)"
    }
}

extension HAR.Browser: CustomDebugStringConvertible {
    // MARK: Describing Browsers

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
    // MARK: Describing Pages

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

    internal static let startedDateFormatter = makeStartedDateFormatter()

    private static func makeStartedDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyyy, h:mm:ss a"
        return formatter
    }
}

extension HAR.Page: CustomDebugStringConvertible {
    // MARK: Describing Pages

    /// A human-readable debug description for the data.
    public var debugDescription: String {
        "HAR.Page { \(description) }"
    }
}

extension HAR.Page: Codable {
    // MARK: Encoding and Decoding

    /// Create Page from Decoder.
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
    // MARK: Describing Page Timings

    /// A human-readable description for the data.
    public var description: String {
        "onContentLoad: \(onContentLoad ?? -1), onLoad: \(onLoad ?? -1)"
    }
}

extension HAR.PageTiming: CustomDebugStringConvertible {
    // MARK: Describing Page Timings

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
    // MARK: Computed Properties

    /// Computed `time` from timings.
    public var computedTime: Double {
        timings.total
    }
}

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

extension HAR.Entry {
    // MARK: Recording an Entry

    /// Perform URL Request and create HTTP archive Entry of the request and response.
    public static func record(request: URLRequest, completionHandler: @escaping (Result<Self, Error>) -> Void) {
        let session = URLSession(
            configuration: URLSessionConfiguration.ephemeral,
            delegate: TaskDelegate(completionHandler),
            delegateQueue: nil
        )
        session.dataTask(with: request).resume()
    }
}

// MARK: - Request

extension HAR.Request: Equatable {}

extension HAR.Request: Hashable {}

extension HAR.Request: CustomStringConvertible {
    // MARK: Describing Requests

    /// A human-readable description for the data.
    public var description: String {
        "\(method) \(url.absoluteString)"
    }
}

extension HAR.Request: CustomDebugStringConvertible {
    // MARK: Describing Requests

    /// A human-readable debug description for the data.
    public var debugDescription: String {
        "HAR.Request { \(description) }"
    }
}

extension HAR.Request: Codable {
    // MARK: Encoding and Decoding

    /// Create Request from Decoder.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Self.CodingKeys.self)

        method = try container.decode(String.self, forKey: .method)
        url = try container.decode(URL.self, forKey: .url)
        httpVersion = try container.decodeIfPresent(String.self, forKey: .httpVersion)
            ?? "HTTP/1.1"
        cookies = try container.decode(HAR.Cookies.self, forKey: .cookies)
        headers = try container.decode(HAR.Headers.self, forKey: .headers)
        queryString = try container.decode(HAR.QueryStrings.self, forKey: .queryString)
        postData = try container.decodeIfPresent(HAR.PostData.self, forKey: .postData)
        headersSize = try container.decodeIfPresent(Int.self, forKey: .headersSize) ?? -1
        bodySize = try container.decodeIfPresent(Int.self, forKey: .bodySize) ?? -1
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
    }
}

extension HAR.Request {
    // MARK: Initializers

    /// Create `Request` with HTTP method and url.
    ///
    /// - Parameter method: An HTTP method.
    /// - Parameter url: A URL.
    public init(method: String, url: URL) {
        self.method = method
        self.url = url

        self.queryString = computedQueryString
        self.headersSize = computedHeadersSize
    }
}

extension HAR.Request {
    // MARK: Computed Properties

    /// Computed `cookies` from headers.
    public var computedCookies: HAR.Cookies {
        headers.value(forName: "Cookie").map {
            HAR.Cookies(fromCookieHeader: $0)
        } ?? []
    }

    /// Computed `queryString` from URL query string.
    public var computedQueryString: HAR.QueryStrings {
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems {
            return queryItems.map { HAR.QueryString($0) }
        }
        return []
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
}

extension HAR.Request {
    // MARK: Initializers

    /// Creates a HAR Request from a URL Request.
    ///
    /// - Parameter request: A URL Request.
    public init(request: URLRequest) {
        /// Empty URL fallback to cover edge case of nil URLRequest.url
        url = URL(string: "about:blank")!
        if let url = request.url {
            self.url = url
        }

        queryString = computedQueryString

        /// - Invariant: `URLRequest.httpMethod` defaults to `"GET"`
        method = request.httpMethod ?? "GET"

        if let headers = request.allHTTPHeaderFields {
            self.headers = HAR.Headers(headers)
        }

        if let data = request.httpBody {
            bodySize = data.count
            postData = HAR.PostData(
                parsingData: data,
                mimeType: headers.value(forName: "Content-Type")
            )
        } else {
            bodySize = 0
        }

        cookies = computedCookies
        headersSize = computedHeadersSize
    }
}

// MARK: - Response

extension HAR.Response: Equatable {}

extension HAR.Response: Hashable {}

extension HAR.Response: CustomStringConvertible {
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
}

extension HAR.Response: CustomDebugStringConvertible {
    // MARK: Describing Responses

    /// A human-readable debug description for the data.
    public var debugDescription: String {
        "HAR.Response { \(description) }"
    }
}

extension HAR.Response: Codable {
    // MARK: Encoding and Decoding

    /// Create Response from Decoder.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Self.CodingKeys.self)

        status = try container.decode(Int.self, forKey: .status)
        statusText = try container.decode(String.self, forKey: .statusText)
        httpVersion = try container.decodeIfPresent(String.self, forKey: .httpVersion)
            ?? "HTTP/1.1"
        cookies = try container.decode(HAR.Cookies.self, forKey: .cookies)
        headers = try container.decode(HAR.Headers.self, forKey: .headers)
        content = try container.decode(HAR.Content.self, forKey: .content)
        redirectURL = try container.decode(String.self, forKey: .redirectURL)
        headersSize = try container.decodeIfPresent(Int.self, forKey: .headersSize) ?? -1
        bodySize = try container.decodeIfPresent(Int.self, forKey: .bodySize) ?? -1
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
    }
}

extension HAR.Response {
    // MARK: Computed Properties

    /// Computed `cookies` from headers.
    public var computedCookies: HAR.Cookies {
        headers.values(forName: "Set-Cookie")
            .map(HAR.Cookie.init(fromSetCookieHeader:))
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

extension HAR.Response {
    // MARK: Static Methods

    private static func statusText(forStatusCode statusCode: Int) -> String {
        switch statusCode {
        case 200:
            return "OK"
        default:
            return HTTPURLResponse.localizedString(forStatusCode: statusCode).capitalized
        }
    }

    // MARK: Initializers

    public init(response: HTTPURLResponse, data: Data?) {
        status = response.statusCode
        statusText = Self.statusText(forStatusCode: response.statusCode)
        headers = HAR.Headers(response.allHeaderFields)

        if let data = data {
            content = HAR.Content(decoding: data, mimeType: response.mimeType)
        } else {
            content = HAR.Content()
        }

        cookies = computedCookies
        headersSize = computedHeadersSize
        bodySize = computedBodySize
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
            value?.trimmingCharacters(in: .whitespaces)
        )
    }
}

/// Split comma seperated Set-Cookie header values.
///
/// HTTPURLResponse does not support multiple headers with the same same. Thus, multiple
/// Set-Cookie headers are join with a comma. Simpling splitting by a comma won't work
/// as it's common for Expire values to include commas in the date string.
///
/// Adapted from `HTTPCookie.cookies(withResponseHeaderFields:for:)`.
/// https://github.com/apple/swift-corelibs-foundation/blob/6167997/Foundation/HTTPCookie.swift#L438
///
private func splitCookieValue(_ cookies: String) -> [String] {
    var values: [String] = []

    func isSpace(_ c: Character) -> Bool {
        c == " " || c == "\t" || c == "\n" || c == "\r"
    }

    func isTokenCharacter(_ c: Character) -> Bool {
        guard let asciiValue = c.asciiValue else {
            return false
        }

        // CTL, 0-31 and DEL (127)
        if asciiValue <= 31 || asciiValue >= 127 {
            return false
        }

        let nonTokenCharacters = "()<>@,;:\\\"/[]?={} \t"
        return !nonTokenCharacters.contains(c)
    }

    var idx = cookies.startIndex
    let end = cookies.endIndex
    while idx < end {
        while idx < end, isSpace(cookies[idx]) {
            idx = cookies.index(after: idx)
        }
        let cookieStartIdx = idx
        var cookieEndIdx = idx

        while idx < end {
            let cookiesRest = cookies[idx ..< end]
            if let commaIdx = cookiesRest.firstIndex(of: ",") {
                var lookaheadIdx = cookies.index(after: commaIdx)
                while lookaheadIdx < end, isSpace(cookies[lookaheadIdx]) {
                    lookaheadIdx = cookies.index(after: lookaheadIdx)
                }
                var tokenLength = 0
                while lookaheadIdx < end, isTokenCharacter(cookies[lookaheadIdx]) {
                    lookaheadIdx = cookies.index(after: lookaheadIdx)
                    tokenLength += 1
                }
                while lookaheadIdx < end, isSpace(cookies[lookaheadIdx]) {
                    lookaheadIdx = cookies.index(after: lookaheadIdx)
                }
                if lookaheadIdx < end, cookies[lookaheadIdx] == "=", tokenLength > 0 {
                    idx = cookies.index(after: commaIdx)
                    cookieEndIdx = commaIdx
                    break
                }
                idx = cookies.index(after: commaIdx)
                cookieEndIdx = idx
            } else {
                idx = end
                cookieEndIdx = end
                break
            }
        }

        if cookieEndIdx <= cookieStartIdx {
            continue
        }

        values.append(String(cookies[cookieStartIdx ..< cookieEndIdx]))
    }

    return values
}

extension HAR.Cookie {
    // MARK: Initializers

    /// Create Cookie from HTTP Response "Set-Cookie" header value.
    fileprivate init(fromSetCookieHeader header: String) {
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
}

extension HAR.Cookies {
    // MARK: Initializers

    /// Create Cookies array from HTTP Request "Cookie:" header value.
    internal init(fromCookieHeader header: String) {
        self = parseCookieAttributes(header).map {
            HAR.Cookie(name: $0.key, value: $0.value ?? "")
        }
    }
}

// MARK: - Headers

extension HAR.Header: Equatable {
    // MARK: Comparing Headers

    /// Returns a Boolean value indicating whether two headers are equal.
    ///
    /// Header names are case-insensitive.
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.name.caseInsensitiveCompare(rhs.name) == .orderedSame &&
            lhs.value == rhs.value &&
            lhs.comment == rhs.comment
    }

    /// Test if header matches case-insensitive name.
    fileprivate func isNamed(_ name: String) -> Bool {
        self.name.caseInsensitiveCompare(name) == .orderedSame
    }
}

extension HAR.Header: Hashable {
    // MARK: Comparing Headers

    /// Hashes the lower case name of the header by feeding them into the given hasher.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name.lowercased())
    }
}

extension HAR.Header: CustomStringConvertible {
    // MARK: Describing Headers

    /// A human-readable description for the data.
    public var description: String {
        "\(name): \(value)"
    }
}

extension HAR.Header: CustomDebugStringConvertible {
    // MARK: Describing Headers

    /// A human-readable debug description for the data.
    public var debugDescription: String {
        "HAR.Header { \(description) }"
    }
}

extension HAR.Header: Codable {}

extension HAR.Headers {
    // MARK: Initializers

    public init(_ fields: [AnyHashable: Any]) {
        self = fields.flatMap { (name, value) -> Self in
            guard let name = name as? String, let value = value as? String else {
                return []
            }

            let header = HAR.Header(name: name, value: value)
            if header.isNamed("Set-Cookie") {
                return splitCookieValue(header.value).map { value in
                    HAR.Header(name: header.name, value: value)
                }
            } else {
                return [header]
            }
        }
    }

    // MARK: Computed Properties

    internal var headersAsDictionary: [String: String] {
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
    internal func values(forName name: String) -> [String] {
        filter { $0.isNamed(name) }.map { $0.value }
    }

    /// Find first header value for name.
    ///
    /// Header names are case-insensitive.
    ///
    /// - Parameter name: The HTTP Header name.
    internal func value(forName name: String) -> String? {
        values(forName: name).first
    }
}

// MARK: - QueryString

extension HAR.QueryString: Equatable {}

extension HAR.QueryString: Hashable {}

extension HAR.QueryString: CustomStringConvertible {
    // MARK: Describing Query Strings

    /// A human-readable description for the data.
    public var description: String {
        "\(name)=\(value)"
    }
}

extension HAR.QueryString: CustomDebugStringConvertible {
    // MARK: Describing Query Strings

    /// A human-readable debug description for the data.
    public var debugDescription: String {
        "HAR.QueryString { \(description) }"
    }
}

extension HAR.QueryString: Codable {}

extension HAR.QueryString {
    // MARK: Initializers

    /// Create QueryString item from `URLQueryItem`.
    internal init(_ queryItem: URLQueryItem) {
        name = queryItem.name
        self.value = queryItem.value?.replacingOccurrences(of: "+", with: " ") ?? ""
    }
}

// MARK: - PostData

extension HAR.PostData: Equatable {}

extension HAR.PostData: Hashable {}

extension HAR.PostData: Codable {
    // MARK: Encoding and Decoding

    /// Create PostData from Decoder.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Self.CodingKeys.self)

        mimeType = try container.decodeIfPresent(String.self, forKey: .mimeType) ?? ""
        params = try container.decodeIfPresent(HAR.Params.self, forKey: .params) ?? []
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
    }
}

extension HAR.PostData {
    // MARK: Initializers

    /// Create HAR PostData from plain text.
    public init(parsingText text: String, mimeType: String?) {
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

    private func parseFormUrlEncoded(_ str: String) -> HAR.Params {
        var components = URLComponents()
        components.query = str
        return components.queryItems?.map {
            return HAR.Param(
                name: $0.name,
                value: $0.value?
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

    // MARK: Computed Properties

    /// Get text as UTF8 Data.
    internal var data: Data {
        Data(text.utf8)
    }

    /// Get bytesize of text.
    internal var size: Int {
        data.count
    }
}

// MARK: - Params

extension HAR.Param: Equatable {}

extension HAR.Param: Hashable {}

extension HAR.Param: CustomStringConvertible {
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
}

extension HAR.Param: CustomDebugStringConvertible {
    // MARK: Describing Params

    /// A human-readable debug description for the data.
    public var debugDescription: String {
        "HAR.Param { \(description) }"
    }
}

extension HAR.Param: Codable {
    // MARK: Encoding and Decoding

    /// Create Param from Decoder.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Self.CodingKeys.self)

        /// Override synthesised decoder to handle empty `name`.
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""

        self.value = try container.decodeIfPresent(String.self, forKey: .value)
        fileName = try container.decodeIfPresent(String.self, forKey: .fileName)
        contentType = try container.decodeIfPresent(String.self, forKey: .contentType)
    }
}

// MARK: - Content

extension HAR.Content: Equatable {}

extension HAR.Content: Hashable {}

extension HAR.Content: Codable {}

extension HAR.Content {
    // MARK: Initializers

    /// Create empty unknown response body content.
    public init() {
        self.size = 0
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
            text = data.base64EncodedString()
            encoding = "base64"
        }
    }

    // MARK: Computed Properties

    /// Empty data
    private static let emptyData = Data(count: 0)

    /// Get content body as Data. May return empty Data if text is encoded improperly.
    public var data: Data {
        guard let text = text else { return Self.emptyData }
        switch encoding {
        case "base64":
            return Data(base64Encoded: text) ?? Self.emptyData
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

extension HAR.Timing: CustomStringConvertible {
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
}

extension HAR.Timing: CustomDebugStringConvertible {
    // MARK: Describing Timings

    /// A human-readable debug description for the data.
    public var debugDescription: String {
        "HAR.Timing {\n\(description)\n}"
    }
}

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

extension HAR.Timing {
    internal init() {
        self.send = -1
        self.wait = -1
        self.receive = -1
    }
}

#if !os(Linux)
@available(iOS 10, macOS 10.12, tvOS 10.0, watchOS 3.0, *)
extension HAR.Timing {
    fileprivate init(metric: URLSessionTaskTransactionMetrics) {
        if let start = metric.fetchStartDate, let end = metric.domainLookupStartDate {
            self.blocked = end.timeIntervalSince(start) * 1000
        }

        if let start = metric.domainLookupStartDate, let end = metric.domainLookupEndDate {
            self.dns = end.timeIntervalSince(start) * 1000
        }

        if let start = metric.connectStartDate, let end = metric.connectEndDate {
            self.connect = end.timeIntervalSince(start) * 1000
        }

        if let start = metric.requestStartDate, let end = metric.requestEndDate {
            self.send = end.timeIntervalSince(start) * 1000
        } else {
            self.send = 0
        }

        if let start = metric.requestEndDate, let end = metric.responseStartDate {
            self.wait = end.timeIntervalSince(start) * 1000
        } else {
            self.wait = 0
        }

        if let start = metric.responseStartDate, let end = metric.responseEndDate {
            self.receive = end.timeIntervalSince(start) * 1000
        } else {
            self.receive = 0
        }

        if let start = metric.secureConnectionStartDate, let end = metric.secureConnectionEndDate {
            self.ssl = end.timeIntervalSince(start) * 1000
        }
    }
}
#endif

// MARK: - Other

private class TaskDelegate: NSObject, URLSessionDataDelegate {
    fileprivate typealias CompletionHandler = (Result<HAR.Entry, Error>) -> Void

    private let completionHandler: CompletionHandler

    fileprivate init(_ completionHandler: @escaping CompletionHandler) {
        self.completionHandler = completionHandler
    }

    private var data: Data = Data()
    private var metric: AnyObject?

    fileprivate func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.data.append(data)
    }

    fileprivate func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let request = task.currentRequest, let response = task.response as? HTTPURLResponse {
            var entry = HAR.Entry(
                request: HAR.Request(request: request),
                response: HAR.Response(response: response, data: data)
            )

#if !os(Linux)
            if #available(iOS 10, macOS 10.12, tvOS 10.0, watchOS 3.0, *) {
                if let metric = self.metric as? URLSessionTaskTransactionMetrics {
                    entry.timings = HAR.Timing(metric: metric)
                    entry.time = entry.timings.total

                    switch metric.networkProtocolName {
                    case "h2":
                        entry.request.httpVersion = "HTTP/2"
                        entry.response.httpVersion = "HTTP/2"
                    case "http/1.1":
                        entry.request.httpVersion = "HTTP/1.1"
                        entry.response.httpVersion = "HTTP/1.1"
                    default:
                        break
                    }
                }
            }
#endif

            completionHandler(.success(entry))
        } else if let error = error {
            completionHandler(.failure(error))
        }
    }
}

#if !os(Linux)
@available(iOS 10, macOS 10.12, tvOS 10.0, watchOS 3.0, *)
extension TaskDelegate {
    fileprivate func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        // Choose last metric, though there might be more accurate of handling
        // multiple metrics.
        metric = metrics.transactionMetrics.last
    }
}
#endif

extension HAR {
    public typealias RecordResult = Result<Self, Error>

    /// Perform URL Request and create HTTP archive of the request and response.
    public static func record(request: URLRequest, completionHandler: @escaping (RecordResult) -> Void) {
        Self.Entry.record(
            request: request,
            completionHandler: {
                completionHandler($0.map { Self(log: Self.Log(entries: [$0])) })
            }
        )
    }

    /// Perform URL Request, create HTTP archive and write encoded archive to file URL.
    public static func record(request: URLRequest, to url: URL, completionHandler: @escaping (RecordResult) -> Void) {
        record(request: request) { result in
            do {
                let har = try result.get()
                try har.write(to: url)
                completionHandler(.success(har))
            } catch (let error) {
                completionHandler(.failure(error))
            }
        }
    }

    /// Attempt to load HAR from file system, otherwise perform request and
    /// write result to file system.
    public static func load(contentsOf url: URL, orRecordRequest request: URLRequest, completionHandler: @escaping (RecordResult) -> Void) {
        do {
            completionHandler(.success(try HAR(contentsOf: url)))
        } catch {
            record(request: request, to: url, completionHandler: completionHandler)
        }
    }
}

extension URLProtocolClient {
    /// Tells the client that the protocol implementation has created a HAR Entry or Error for the request.
    public func urlProtocol(_ protocol: URLProtocol, didLoadEntryResult result: Result<HAR.Entry, Error>) {
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

#if canImport(FoundationNetworking)
public typealias FoundationURLProtocol = FoundationNetworking.URLProtocol
#else
public typealias FoundationURLProtocol = Foundation.URLProtocol
#endif

extension HAR {
    open class URLProtocol: FoundationURLProtocol {
        public static var configuration: URLSessionConfiguration {
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [Self.self]
            return config
        }

        public static var session: URLSession {
            URLSession(configuration: configuration)
        }

        public override class func canInit(with _: URLRequest) -> Bool {
            true
        }

        public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }

        open override func startLoading() {
            fatalError("URLProtocol.startLoading must be implemented")
        }

        public func startLoading(url: URL, entrySelector: @escaping (HAR.Log) -> HAR.Entry = { $0.firstEntry }) {
            HAR.load(contentsOf: url, orRecordRequest: request) { result in
                self.client?.urlProtocol(self, didLoadEntryResult: result.map { har in entrySelector(har.log) })
            }
        }

        public override func stopLoading() {}
    }
}
