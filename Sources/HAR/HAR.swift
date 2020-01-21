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

public struct HAR: Codable, Equatable {
    public var log: Log

    /// This object represents the root of exported data.
    ///
    /// There is one `Page` object for every exported web page and one `Entry` object for every HTTP request. In case when an HTTP trace tool isn't able to group requests by a page, the `pages` object is empty and individual requests doesn't have a parent page.
    public struct Log: Codable, Equatable {
        /// Version number of the format. If empty, string "1.1" is assumed by default.
        public var version: String = "1.1"

        /// Name and version info of the log creator application.
        public var creator: Creator

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

    public struct Creator: Codable, Equatable {
        /// Name of the application/browser used to export the log.
        public var name: String

        /// Version of the application/browser used to export the log.
        public var version: String

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

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

    /// This object represents list of exported pages.
    public struct Page: Codable, Equatable {
        /// Date and time stamp for the beginning of the page load.
        public var startedDateTime: Date

        /// Unique identifier of a page within the `Log`. Entries use it to refer the parent page.
        public var id: String

        /// Page title.
        ///
        /// - Note: Spec requires value, but real world .har files sometimes omit it.
        public var title: String?

        /// Detailed timing info about page load.
        public var pageTimings: PageTiming

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    /// This object describes timings for various events (states) fired during the page load. All times are specified in milliseconds. If a time info is not available appropriate field is set to -1.
    ///
    /// Depending on the browser, onContentLoad property represents `DOMContentLoad` event or `document.readyState == interactive`.
    public struct PageTiming: Codable, Equatable {
        /// Content of the page loaded. Number of milliseconds since page load started (`page.startedDateTime`). Use -1 if the timing does not apply to the current request.
        public var onContentLoad: Double?

        /// Page is loaded (onLoad event fired). Number of milliseconds since page load started (`page.startedDateTime`). Use -1 if the timing does not apply to the current request.
        public var onLoad: Double?

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    /// This object represents an array with all exported HTTP requests. Sorting entries by `startedDateTime` (starting from the oldest) is preferred way how to export data since it can make importing faster. However the reader application should always make sure the array is sorted (if required for the import).
    public struct Entry: Codable, Equatable {
        /// Reference to the parent page. Leave out this field if the application does not support grouping by pages.
        public var pageref: String?

        /// Date and time stamp of the request start.
        public var startedDateTime: Date

        /// Total elapsed time of the request in milliseconds. This is the sum of all timings available in the timings object (i.e. not including -1 values) .
        ///
        /// - Invariant: The time value for the request must be equal to the sum of the timings supplied in this section (excluding any -1 values).
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

        /// Unique ID of the parent TCP/IP connection, can be the client or server port number. Note that a port number doesn't have to be unique identifier in cases where the port is shared for more connections. If the port isn't available for the application, any other unique connection ID can be used instead (e.g. connection index). Leave out this field if the application doesn't support this info.
        ///
        /// - Version: 1.2
        public var connection: String?

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    public enum HTTPMethod: String, Codable {
        case get = "GET"
        case head = "HEAD"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
        case connect = "CONNECT"
        case options = "OPTIONS"
        case trace = "TRACE"
        case patch = "PATCH"
    }

    /// This object contains detailed info about performed request.
    public struct Request: Codable, Equatable {
        /// Request method.
        public var method: HTTPMethod

        /// Absolute URL of the request (fragments are not included).
        public var url: String

        /// Request HTTP Version.
        public var httpVersion: String

        /// List of cookie objects.
        public var cookies: [Cookie] = []

        /// List of header objects.
        public var headers: [Header] = []

        /// List of query parameter objects.
        public var queryString: [QueryString] = []

        /// Posted data info.
        public var postData: PostData?

        /// Total number of bytes from the start of the HTTP request message until (and including) the double CRLF before the body. Set to -1 if the info is not available.
        public var headersSize: Int = -1

        /// Size of the request body (POST data payload) in bytes. Set to -1 if the info is not available.
        public var bodySize: Int = -1

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    /// This object contains detailed info about the response.
    public struct Response: Codable, Equatable {
        /// Response status.
        public var status: Int

        /// Response status description.
        public var statusText: String

        /// Response HTTP Version.
        public var httpVersion: String

        /// List of cookie objects.
        public var cookies: [Cookie] = []

        /// List of header objects.
        public var headers: [Header] = []

        /// Details about the response body.
        public var content: Content

        /// Redirection target URL from the Location response header.
        public var redirectURL: String

        /// Total number of bytes from the start of the HTTP response message until (and including) the double CRLF before the body. Set to -1 if the info is not available.
        ///
        /// The size of received response-headers is computed only from headers that are really received from the server. Additional headers appended by the browser are not included in this number, but they appear in the list of header objects.
        public var headersSize: Int

        /// Size of the received response body in bytes. Set to zero in case of responses coming from the cache (304). Set to -1 if the info is not available.
        public var bodySize: Int

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    /// This object contains list of all cookies (used in `Request` and `Response` objects).
    public struct Cookie: Codable, Equatable {
        /// The name of the cookie.
        public var name: String

        /// The cookie value.
        public var value: String

        /// The path pertaining to the cookie.
        public var path: String? = nil

        // The host of the cookie.
        public var domain: String? = nil

        /// Cookie expiration time.
        public var expires: Date? = nil

        /// Set to true if the cookie is HTTP only, false otherwise.
        public var httpOnly: Bool? = nil

        /// True if the cookie was transmitted over ssl, false otherwise.
        ///
        /// - Version: 1.2
        public var secure: Bool? = nil

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?

        /// The SameSite cross-origin policy of the cookie.
        ///
        /// Possible values: `"strict"`, `"lax"`, `"none"`
        ///
        /// - Version: Unspecified
        public var sameSite: String? = nil
    }

    /// This object contains list of all headers (used in `Request` and `Response` objects).
    public struct Header: Codable, Equatable {
        public var name: String
        public var value: String

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    /// This object contains list of all parameters & values parsed from a query string, if any (embedded in `Request` object).
    public struct QueryString: Codable, Equatable {
        public var name: String
        public var value: String

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?
    }

    /// This object describes posted data, if any (embedded in `Request` object).
    public struct PostData: Codable, Equatable {
        /// Mime type of posted data.
        public var mimeType: String

        /// List of posted parameters (in case of URL encoded parameters).
        ///
        /// - Invariant: Text and params fields are mutually exclusive.
        public var params: [Param] = []

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
    public struct Param: Codable, Equatable {
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

    /// This object describes details about response content (embedded in `Response` object).
    public struct Content: Codable, Equatable {
        /// Length of the returned content in bytes. Should be equal to `response.bodySize` if there is no compression and bigger when the content has been compressed.
        public var size: Int

        /// Number of bytes saved. Leave out this field if the information is not available.
        public var compression: Int?

        /// MIME type of the response text (value of the Content-Type response header). The charset attribute of the MIME type is included (if available).
        public var mimeType: String?

        ///  Response body sent from the server or loaded from the browser cache. This field is populated with textual content only. The text field is either HTTP decoded text or a encoded (e.g. "base64") representation of the response body. Leave out this field if the information is not available.
        ///
        /// Before setting the text field, the HTTP response is decoded (decompressed & unchunked), than trans-coded from its original character set into UTF-8. Additionally, it can be encoded using e.g. base64. Ideally, the application should be able to unencode a base64 blob and get a byte-for-byte identical resource to what the browser operated on.
        public var text: String?

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

    /// This object describes various phases within request-response round trip. All times are specified in milliseconds.
    public struct Timing: Codable, Equatable {
        /// Time spent in a queue waiting for a network connection. Use -1 if the timing does not apply to the current request.
        public var blocked: Double = -1

        /// DNS resolution time. The time required to resolve a host name. Use -1 if the timing does not apply to the current request.
        public var dns: Double = -1

        ///  Time required to create TCP connection. Use -1 if the timing does not apply to the current request.
        public var connect: Double = -1

        /// Time required to send HTTP request to the server.
        public var send: Double

        /// Waiting for a response from the server.
        public var wait: Double

        /// Time required to read entire response from the server (or cache).
        public var receive: Double

        /// Time required for SSL/TLS negotiation. If this field is defined then the time is also included in the connect field (to ensure backward compatibility with HAR 1.1). Use -1 if the timing does not apply to the current request.
        ///
        /// - Version: 1.2
        public var ssl: Double = -1

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
    init(contentsOf url: URL) throws {
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
    init(data: Data) throws {
        let decoder = JSONDecoder()

        decoder.dateDecodingStrategy = .custom { (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)

            if let date = HAR.dateFormatter.date(from: dateStr) {
                return date
            }

            throw Swift.DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "invalid date: \(dateStr)")
        }

        self = try decoder.decode(HAR.self, from: data)
    }

    /// Returns a HAR encoded as JSON `Data`.
    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .formatted(HAR.dateFormatter)
        return try encoder.encode(self)
    }
}

extension URLRequest {
    /// Creates a URL Request from a `HAR.Request`.
    ///
    /// - Parameter har: A `HAR.Request`.
    init(har: HAR.Request) {
        // FIXME: Do not force unwrap URL.
        let url = URL(string: har.url)!
        self.init(url: url)
        httpMethod = har.method.rawValue
        for header in har.headers {
            setValue(header.value, forHTTPHeaderField: header.name)
        }
        if let postData = har.postData {
            httpBody = postData.text.data(using: .utf8)
        }
    }
}

extension HAR.Request {
    /// Creates a HAR Request from a URL Request.
    ///
    /// - Parameter request: A URL Request.
    init(request: URLRequest) {
        method = .get
        if let httpMethod = request.httpMethod, let method = HAR.HTTPMethod(rawValue: httpMethod) {
            self.method = method
        }

        url = "about:blank"
        if let url = request.url {
            self.url = url.absoluteString
        }

        httpVersion = "HTTP/1.1"

        if let cookie = request.value(forHTTPHeaderField: "Cookie") {
            cookies = parseFormUrlEncoded(cookie).map {
                HAR.Cookie(name: $0.key, value: $0.value ?? "")
            }
        }

        if let headers = request.allHTTPHeaderFields {
            for (name, value) in headers {
                self.headers.append(HAR.Header(name: name, value: value))
            }
        }

        // TODO:
        queryString = []

        if let data = request.httpBody {
            let mimeType = request.value(forHTTPHeaderField: "Content-Type") ?? "application/x-www-form-urlencoded; charset=UTF-8"
            let text = String(bytes: data, encoding: .utf8)! // FIXME:
            postData = HAR.PostData(text: text, mimeType: mimeType)
        }
    }
}

internal func parseFormUrlEncoded(_ str: String) -> [(key: String, value: String?)] {
    var components = URLComponents()
    components.query = str
    return components.queryItems?.map { ($0.name, $0.value) } ?? []
}

extension HAR.Param {
    /// Create HAR Param from `(key, value)` tuple.
    init(_ pair: (key: String, value: String?)) {
        name = pair.key
        value = pair.value
    }
}

extension HAR.PostData {
    /// Create HAR PostData from plain text.
    init(text: String, mimeType: String) {
        self.mimeType = mimeType
        self.text = text

        if mimeType.hasPrefix("application/x-www-form-urlencoded") {
            params = parseFormUrlEncoded(text).map { HAR.Param($0) }
        }
    }
}
