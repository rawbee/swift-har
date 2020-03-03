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

extension HAR.Request {
    /// Creates a HAR Request from a URL Request.
    ///
    /// - Parameter request: A URL Request.
    public init(request: URLRequest) {
        self.postData = nil
        self.headersSize = -1
        self.bodySize = -1
        self.comment = nil

        /// - Invariant: `URLRequest.httpMethod` defaults to `"GET"`
        self.method = request.httpMethod ?? "GET"

        self.httpVersion = "HTTP/1.1"

        /// Empty URL fallback to cover edge case of nil URLRequest.url
        self.url = URL(string: "about:blank")!
        if let url = request.url {
            self.url = url
        }

        self.queryString = computedQueryString

        if let headers = request.allHTTPHeaderFields {
            self.headers = HAR.Headers(headers)
        }

        if let data = request.httpBody {
            self.bodySize = data.count
            self.postData = HAR.PostData(
                parsingData: data,
                mimeType: headers.value(forName: "Content-Type")
            )
        } else {
            self.bodySize = 0
        }

        self.cookies = computedCookies
        self.headersSize = computedHeadersSize
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

extension HAR.Response {
    // MARK: Initializers

    /// Creates a archived Response from a `HTTPURLResponse` and HTTP Body `Data`.
    public init(response: HTTPURLResponse, data: Data?) {
        self.status = response.statusCode
        self.statusText = Self.statusText(forStatusCode: response.statusCode)
        self.httpVersion = "HTTP/1.1"
        self.cookies = []
        self.headers = HAR.Headers(response.allHeaderFields)
        self.redirectURL = ""
        self.headersSize = -1
        self.bodySize = -1
        self.comment = nil

        if let data = data {
            self.content = HAR.Content(decoding: data, mimeType: response.mimeType)
        } else {
            self.content = HAR.Content()
        }

        self.cookies = computedCookies
        self.headersSize = computedHeadersSize
        self.bodySize = computedBodySize
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
}

#if !os(Linux)
@available(iOS 10, macOS 10.12, tvOS 10.0, watchOS 3.0, *)
extension HAR.Timing {
    // MARK: Initializers

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

        self.comment = nil
    }
}
#endif

private class TaskDelegate: NSObject, URLSessionDataDelegate {
    // MARK: Type Aliases

    fileprivate typealias CompletionHandler = (Result<HAR.Entry, Error>) -> Void

    // MARK: Initializers

    fileprivate init(_ completionHandler: @escaping CompletionHandler) {
        self.completionHandler = completionHandler
    }

    // MARK: Instance Properties

    private let completionHandler: CompletionHandler
    private var data: Data = Data()
    private var metric: AnyObject?

    // MARK: Instance Methods

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
    // MARK: Instance Methods

    fileprivate func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        // Choose last metric, though there might be more accurate of handling
        // multiple metrics.
        metric = metrics.transactionMetrics.last
    }
}
#endif

extension HAR {
    // MARK: Recording an HAR

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
    // MARK: Instance Methods

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

extension HAR {
#if canImport(FoundationNetworking)
    public typealias FoundationURLProtocol = FoundationNetworking.URLProtocol
#else
    public typealias FoundationURLProtocol = Foundation.URLProtocol
#endif

    open class URLProtocol: FoundationURLProtocol {
        // MARK: Instance Properties

        public static var configuration: URLSessionConfiguration {
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [Self.self]
            return config
        }

        public static var session: URLSession {
            URLSession(configuration: configuration)
        }

        // MARK: Instance Methods

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
