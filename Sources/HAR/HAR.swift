//
//  HAR
//
//  MIT License
//
//  Copyright (c) 2020 Joshua Peek
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct HAR: Codable, Equatable {
    public var log: Log

    // MARK: - Log

    /// This object represents the root of exported data.
    ///
    /// There is one `Page` object for every exported web page and one `Entry` object for every HTTP request. In case when an HTTP trace tool isn't able to group requests by a page, the `pages` object is empty and individual requests doesn't have a parent page.
    public struct Log: Codable, Equatable {
        /// Version number of the format. If empty, string "1.1" is assumed by default.
        public var version: String = "1.2"

        /// Name and version info of the log creator application.
        public var creator: Creator = Creator.defaultCreator

        /// Name and version info of used browser.
        public var browser: Browser?

        /// List of all exported (tracked) pages. Leave out this field if the application does not support grouping by pages.
        public var pages: [Page]?

        /// List of all exported (tracked) requests.
        public var entries: [Entry] = []

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    // MARK: - Creator

    public struct Creator: Codable, Equatable {
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

    public struct Browser: Codable, Equatable {
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
    public struct Page: Codable, Equatable {
        /// Date and time stamp for the beginning of the page load.
        public var startedDateTime: Date

        /// Unique identifier of a page within the `Log`. Entries use it to refer the parent page.
        public var id: String

        /// Page title.
        ///
        /// - Note: Spec requires value, but real world .har files sometimes omit it.
        public var title: String? = ""

        /// Detailed timing info about page load.
        public var pageTimings: PageTiming = PageTiming()

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    // MARK: - PageTimings

    /// This object describes timings for various events (states) fired during the page load. All times are specified in milliseconds. If a time info is not available appropriate field is set to -1.
    ///
    /// Depending on the browser, onContentLoad property represents `DOMContentLoad` event or `document.readyState == interactive`.
    public struct PageTiming: Codable, Equatable {
        /// Content of the page loaded. Number of milliseconds since page load started (`page.startedDateTime`). Use -1 if the timing does not apply to the current request.
        public var onContentLoad: Double? = -1

        /// Page is loaded (onLoad event fired). Number of milliseconds since page load started (`page.startedDateTime`). Use -1 if the timing does not apply to the current request.
        public var onLoad: Double? = -1

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    // MARK: - Entries

    /// This object represents an array with all exported HTTP requests. Sorting entries by `startedDateTime` (starting from the oldest) is preferred way how to export data since it can make importing faster. However the reader application should always make sure the array is sorted (if required for the import).
    public struct Entry: Codable, Equatable {
        /// Reference to the parent page. Leave out this field if the application does not support grouping by pages.
        public var pageref: String?

        /// Date and time stamp of the request start.
        public var startedDateTime: Date = Date()

        /// Total elapsed time of the request in milliseconds. This is the sum of all timings available in the timings object (i.e. not including -1 values) .
        ///
        /// - Invariant: The time value for the request must be equal to the sum of the timings supplied in this section (excluding any -1 values).
        public var time: Double = 0

        /// Detailed info about the request.
        public var request: Request

        /// Detailed info about the response.
        public var response: Response

        /// Info about cache usage.
        public var cache: Cache = Cache()

        /// Detailed timing info about request/response round trip.
        public var timings: Timing = Timing() {
            didSet {
                time = timings.total
            }
        }

        /// IP address of the server that was connected (result of DNS resolution).
        ///
        /// - Version: 1.2
        public var serverIPAddress: String?

        /// Unique ID of the parent TCP/IP connection, can be the client or server port number. Note that a port number doesn't have to be unique identifier in cases where the port is shared for more connections. If the port isn't available for the application, any other unique connection ID can be used instead (e.g. connection index). Leave out this field if the application doesn't support this info.
        ///
        /// - Version: 1.2
        public var connection: String?

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    // MARK: - Request

    /// This object contains detailed info about performed request.
    public struct Request: Codable, Equatable {
        /// Request method.
        public var method: String = "GET" {
            didSet {
                updateHeadersSize()
            }
        }

        /// Empty URL when none is provided.
        private static let blankUrl = URL(string: "about:blank")!

        /// Absolute URL of the request (fragments are not included).
        public var url: URL = Self.blankUrl {
            didSet {
                if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
                    queryString = queryItems.map {
                        QueryString($0)
                    }
                }

                updateHeadersSize()
            }
        }

        /// Request HTTP Version.
        public var httpVersion: String? = "HTTP/1.1" {
            didSet {
                updateHeadersSize()
            }
        }

        /// List of cookie objects.
        public var cookies: Cookies = []

        /// List of header objects.
        public var headers: Headers = [] {
            didSet {
                if let value = value(forHTTPHeaderField: "Cookie") {
                    cookies = Cookies(fromCookieHeader: value)
                }

                updateHeadersSize()
            }
        }

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
        public var queryString: [QueryString] = []

        /// Posted data info.
        public var postData: PostData? {
            didSet {
                bodySize = postData?.data?.count ?? -1
            }
        }

        /// Total number of bytes from the start of the HTTP request message until (and including) the double CRLF before the body. Set to -1 if the info is not available.
        ///
        /// - Important: Should be ran when mutating `method`, `url`, `httpVersion` or `headers`.
        public var headersSize: Int = -1

        /// Compute and update `headerSize`.
        private mutating func updateHeadersSize() {
            headersSize = Data(headerText.utf8).count
        }

        /// Compute text representation of header for computing it's size.
        private var headerText: String {
            """
            \(method) \(url.relativePath) \(httpVersion ?? "HTTP/1.1")\r
            \(headers.map { "\($0.name): \($0.value)\r\n" }.joined())\r\n
            """
        }

        /// Size of the request body (POST data payload) in bytes. Set to -1 if the info is not available.
        public var bodySize: Int = 0

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?

        /// Create empty `Header` structure.
        private init() {
            // Run didSet hooks
            defer {
                self.url = self.url
                headers = headers
                postData = postData
            }
        }

        /// Create `Request` with HTTP method and url.
        ///
        /// - Parameter method: An HTTP method.
        /// - Parameter url: A URL.
        init(method: String, url: URL) {
            self.init()

            self.method = method
            self.url = url

            // Run didSet hooks
            defer {
                self.url = self.url
                headers = headers
            }
        }
    }

    // MARK: - Response

    /// This object contains detailed info about the response.
    public struct Response: Codable, Equatable {
        /// Response status.
        public var status: Int = 200 {
            didSet {
                self.statusText = HTTPURLResponse.localizedString(forStatusCode: status).capitalized
                updateHeadersSize()
            }
        }

        /// Response status description.
        public var statusText: String = "OK"

        /// Response HTTP Version.
        public var httpVersion: String? = "HTTP/1.1"

        /// List of cookie objects.
        public var cookies: Cookies = []

        /// List of header objects.
        public var headers: Headers = [] {
            didSet {
                for header in headers {
                    if header.name.lowercased() == "set-cookie" {
                        cookies.append(Cookie(fromSetCookieHeader: header.value))
                    }
                }

                updateHeadersSize()
            }
        }

        /// Details about the response body.
        public var content: Content = Content()

        /// Redirection target URL from the Location response header.
        public var redirectURL: String = ""

        /// Total number of bytes from the start of the HTTP response message until (and including) the double CRLF before the body. Set to -1 if the info is not available.
        ///
        /// The size of received response-headers is computed only from headers that are really received from the server. Additional headers appended by the browser are not included in this number, but they appear in the list of header objects.
        public var headersSize: Int = -1

        /// Compute and update `headerSize`.
        private mutating func updateHeadersSize() {
            headersSize = Data(headerText.utf8).count
        }

        /// Compute text representation of header for computing it's size.
        private var headerText: String {
            """
            \(status) \(statusText)\r
            \(headers.map { "\($0.name): \($0.value)\r\n" }.joined())\r\n
            """
        }

        /// Size of the received response body in bytes. Set to zero in case of responses coming from the cache (304). Set to -1 if the info is not available.
        public var bodySize: Int = -1

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    // MARK: - Cookies

    /// This object contains list of all cookies (used in `Request` and `Response` objects).
    public struct Cookie: Codable, Equatable {
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

    /// This object contains list of all headers (used in `Request` and `Response` objects).
    public struct Header: Codable, Equatable {
        public var name: String
        public var value: String

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    public typealias Headers = [Header]

    // MARK: - QueryString

    /// This object contains list of all parameters & values parsed from a query string, if any (embedded in `Request` object).
    public struct QueryString: Codable, Equatable {
        public var name: String
        public var value: String

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    // MARK: - PostData

    /// This object describes posted data, if any (embedded in `Request` object).
    public struct PostData: Codable, Equatable {
        /// Mime type of posted data.
        public var mimeType: String = "application/octet-stream"

        /// List of posted parameters (in case of URL encoded parameters).
        ///
        /// - Invariant: Text and params fields are mutually exclusive.
        public var params: [Param]? = []

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
    public struct Param: Codable, Equatable {
        /// Name of a posted parameter.
        public var name: String?

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

    // MARK: - Content

    /// This object describes details about response content (embedded in `Response` object).
    public struct Content: Codable, Equatable {
        /// Length of the returned content in bytes. Should be equal to `response.bodySize` if there is no compression and bigger when the content has been compressed.
        public var size: Int = 0

        /// Number of bytes saved. Leave out this field if the information is not available.
        public var compression: Int?

        /// MIME type of the response text (value of the Content-Type response header). The charset attribute of the MIME type is included (if available).
        public var mimeType: String?

        ///  Response body sent from the server or loaded from the browser cache. This field is populated with textual content only. The text field is either HTTP decoded text or a encoded (e.g. "base64") representation of the response body. Leave out this field if the information is not available.
        ///
        /// Before setting the text field, the HTTP response is decoded (decompressed & unchunked), than trans-coded from its original character set into UTF-8. Additionally, it can be encoded using e.g. base64. Ideally, the application should be able to unencode a base64 blob and get a byte-for-byte identical resource to what the browser operated on.
        public var text: String? {
            didSet {
                size = data?.count ?? 0
            }
        }

        /// Encoding used for response text field e.g "base64". Leave out this field if the text field is HTTP decoded (decompressed & unchunked), than trans-coded from its original character set into UTF-8.
        ///
        /// Encoding field is useful for including binary responses (e.g. images) into the HAR file.
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
    public struct Cache: Codable, Equatable {
        // State of a cache entry before the request. Leave out this field if the information is not available.
        public var beforeRequest: CacheEntry?

        /// State of a cache entry after the request. Leave out this field if the information is not available.
        public var afterRequest: CacheEntry?

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    public struct CacheEntry: Codable, Equatable {
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

    /// This object describes various phases within request-response round trip. All times are specified in milliseconds.
    public struct Timing: Codable, Equatable {
        /// Time spent in a queue waiting for a network connection. Use -1 if the timing does not apply to the current request.
        public var blocked: Double? = -1

        /// DNS resolution time. The time required to resolve a host name. Use -1 if the timing does not apply to the current request.
        public var dns: Double? = -1

        ///  Time required to create TCP connection. Use -1 if the timing does not apply to the current request.
        public var connect: Double? = -1

        /// Time required to send HTTP request to the server.
        public var send: Double = 0

        /// Waiting for a response from the server.
        public var wait: Double = 0

        /// Time required to read entire response from the server (or cache).
        public var receive: Double = 0

        /// Time required for SSL/TLS negotiation. If this field is defined then the time is also included in the connect field (to ensure backward compatibility with HAR 1.1). Use -1 if the timing does not apply to the current request.
        ///
        /// - Version: 1.2
        public var ssl: Double? = -1

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }
}

extension HAR {
    /// Creates a `HAR` from the contents of a file URL.
    ///
    /// - Parameter url: Path to `.har` file.
    public init(contentsOf url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    /// Return ISO 8601 date formatter.
    ///
    /// Uses the format `YYYY-MM-DDThh:mm:ss.sTZD` to return a date such as `2009-07-24T19:20:30.45+01:00`.
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
        self.init()

        if let url = request.url {
            self.url = url
        }

        /// - Invariant: `URLRequest.httpMethod` defaults to `"GET"`
        method = request.httpMethod ?? "GET"

        if let headers = request.allHTTPHeaderFields {
            self.headers = headers.map { HAR.Header($0) }
        }

        if let data = request.httpBody {
            postData = HAR.PostData(data: data, mimeType: value(forHTTPHeaderField: "Content-Type"))
        }

        // Run didSet hooks
        defer {
            self.method = self.method
            self.url = self.url
            self.headers = self.headers
            self.postData = self.postData
        }
    }
}

extension HTTPURLResponse {
    public convenience init(url: URL, response: HAR.Response) {
        let headerFields = response.headers.reduce(into: [:]) { $0[$1.name] = $1.value }

        /// - Remark: initializer doesn't appear to have any failure cases
        self.init(url: url, statusCode: response.status, httpVersion: response.httpVersion, headerFields: headerFields)!
    }
}

extension HAR.Response {
    init(response: HTTPURLResponse, data: Data?) {
        status = response.statusCode
        headers = HAR.Headers(response.allHeaderFields)
        bodySize = Int(truncatingIfNeeded: response.expectedContentLength)

        if let data = data {
            content = HAR.Content(data: data, size: bodySize, mimeType: response.mimeType)
        }

        defer {
            self.status = self.status
            self.headers = self.headers
        }
    }
}

func breakIntoHalfs(_ string: String, separatedBy: String) -> (String, String?) {
    var components = string.components(separatedBy: separatedBy)
    let first = components.removeFirst()
    let rest = components.joined(separator: separatedBy)
    return (first, rest.isEmpty ? nil : rest)
}

/// Parse cookie style attribute pairs seperated by `;` and `=`
func parseCookieAttributes(_ string: String) -> [(key: String, value: String?)] {
    string.components(separatedBy: ";").compactMap {
        let (key, value) = breakIntoHalfs($0, separatedBy: "=")
        return (key.trimmingCharacters(in: .whitespaces), value?.trimmingCharacters(in: .whitespaces))
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
                    // Tue, 18 Jan 2022 23:07:07 GMT
                    for dateFormat in ["EEE',' dd MMM yyyy HH:mm:ss 'GMT'", "EEE',' dd'-'MMM'-'yy HH:mm:ss 'GMT'", "EEE',' dd'-'MMM'-'yyyy HH:mm:ss 'GMT'"] {
                        let formatter = DateFormatter()
                        formatter.timeZone = TimeZone(identifier: "UTC")
                        formatter.dateFormat = dateFormat

                        expires = formatter.date(from: value)
                        if expires != nil {
                            break
                        }
                    }

                    if expires == nil {
                        print("bad parse: \(value)")
                    }
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
}

extension HAR.Cookies {
    init(fromCookieHeader header: String) {
        self = parseCookieAttributes(header).map { HAR.Cookie(name: $0.key, value: $0.value ?? "") }
    }
}

extension HAR.Header {
    /// Create HAR Header from `(key, value)` tuple.
    init(_ pair: (key: String, value: String)) {
        name = pair.key
        value = pair.value
    }
}

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

extension HAR.QueryString {
    init(_ queryItem: URLQueryItem) {
        self.init(
            name: queryItem.name,
            value: queryItem.value?.replacingOccurrences(of: "+", with: " ") ?? "")
    }
}

extension HAR.PostData {
    /// Create HAR PostData from plain text.
    init(text: String, mimeType: String?) {
        self.text = text

        if let mimeType = mimeType {
            self.mimeType = mimeType
        }

        if self.mimeType.hasPrefix("application/x-www-form-urlencoded") {
            params = parseFormUrlEncoded(text)
        }
    }

    internal func parseFormUrlEncoded(_ str: String) -> [HAR.Param] {
        var components = URLComponents()
        components.query = str
        return components.queryItems?.map {
            return HAR.Param(
                name: $0.name,
                value: $0.value?.replacingOccurrences(of: "+", with: "%20").removingPercentEncoding ?? "")
        } ?? []
    }

    /// Create HAR PostData from data.
    init?(data: Data, mimeType: String?) {
        guard let text = String(bytes: data, encoding: .utf8) else {
            return nil
        }
        self.init(text: text, mimeType: mimeType)
    }

    var data: Data? {
        Data(text.utf8)
    }
}

extension HAR.Param {
    /// Create HAR Param from `(key, value)` tuple.
    init(_ pair: (key: String, value: String?)) {
        name = pair.key
        value = pair.value
    }
}

extension HAR.Content {
    /// - ToDo: Document initializer.
    init(text: String, encoding: String? = nil, mimeType: String) {
        self.encoding = encoding
        self.mimeType = mimeType

        // Run didSet hooks
        defer {
            self.text = text
        }
    }

    /// - ToDo: Document initializer.
    init(data: Data, size: Int, mimeType: String?) {
        self.size = size
        self.mimeType = mimeType

        if let text = String(bytes: data, encoding: .utf8) {
            self.text = text
        } else {
            text = data.base64EncodedString()
            encoding = "base64"
        }

        // Run didSet hooks
        defer {
            self.text = text
        }
    }

    /// - ToDo: Document property.
    public var data: Data? {
        if let text = text {
            switch encoding {
            case "base64":
                return Data(base64Encoded: text)
            default:
                return Data(text.utf8)
            }
        }
        return nil
    }
}

extension HAR.Timing {
    /// Compute total request time.
    ///
    /// The time value for the request must be equal to the sum of the timings supplied in this section (excluding any -1 values).
    public var total: Double {
        [blocked, dns, connect, send, wait, receive]
            .map { $0 ?? -1 }
            .filter { $0 != -1 }
            .reduce(0, +)
    }
}

extension HAR.Entry {
    public static func record(request: URLRequest, completionHandler: @escaping (Result<Self, Error>) -> Void) {
        var timings = HAR.Timing()
        let start = DispatchTime.now()

        let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
            timings.receive = Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1000000

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
        try SyncResult { record(request: request, completionHandler: $0) }
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
        try SyncResult { Self.record(request: request, completionHandler: $0) }
    }
}

internal func SyncResult<T>(_ asyncHandler: (@escaping (Result<T, Error>) -> Void) -> Void) throws -> T {
    let semaphore = DispatchSemaphore(value: 0)
    var result: Result<T, Error>?

    asyncHandler { (_result: Result<T, Error>) in
        result = _result
        semaphore.signal()
    }

    _ = semaphore.wait(timeout: .distantFuture)
    return try result!.get()
}
