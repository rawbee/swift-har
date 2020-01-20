//
//  HAR
//
//  Copyright © 2020 Joshua Peek.
//  MIT license, see LICENSE file for details.
//

import Foundation

public struct HAR: Codable, Equatable {
    public var log: Log

    public struct Log: Codable, Equatable {
        public var version: String = "1.1"
        public var creator: Creator
        public var browser: Browser?
        public var pages: [Page]?
        public var entries: [Entry] = []
    }

    public struct Creator: Codable, Equatable {
        public var name: String
        public var version: String
    }

    public struct Browser: Codable, Equatable {
        public var name: String
        public var version: String
    }

    public struct Page: Codable, Equatable {
        public var startedDateTime: String
        public var id: String
        public var title: String? // Not supposed to be optional
        public var pageTimings: PageTiming
    }

    public struct PageTiming: Codable, Equatable {
        public var onContentLoad: Double?
        public var onLoad: Double?
    }

    public struct Entry: Codable, Equatable {
        public var pageref: String?
        public var startedDateTime: String
        public var time: Double
        public var request: Request
        public var response: Response
        public var cache: Cache
        public var timings: Timing
        public var serverIPAddress: String?
        public var connection: String?
    }

    public struct Request: Codable, Equatable {
        public var method: String
        public var url: String
        public var httpVersion: String
        public var cookies: [Cookie] = []
        public var headers: [Header] = []
        public var queryString: [QueryString] = []
        public var postData: PostData?
        public var headersSize: Int = -1
        public var bodySize: Int = -1
    }

    public struct Response: Codable, Equatable {
        public var status: Int
        public var statusText: String
        public var httpVersion: String
        public var cookies: [Cookie] = []
        public var headers: [Header] = []
        public var content: Content
        public var redirectURL: String
        public var headersSize: Int
        public var bodySize: Int
    }

    public struct Cookie: Codable, Equatable {
        public var name: String
        public var value: String
        public var path: String?
        public var domain: String?
        public var expires: String?
        public var httpOnly: Bool?
        public var secure: Bool?

        // Non-standard
        public var sameSite: String?
    }

    public struct Header: Codable, Equatable {
        public var name: String
        public var value: String
    }

    public struct QueryString: Codable, Equatable {
        public var name: String
        public var value: String
    }

    public struct PostData: Codable, Equatable {
        public var mimeType: String
        public var params: [Param] = []
        public var text: String
    }

    public struct Param: Codable, Equatable {
        public var name: String
        public var value: String?
    }

    public struct Content: Codable, Equatable {
        public var size: Int
        public var compression: Int?
        public var mimeType: String?
        public var text: String?
        public var encoding: String?
    }

    public struct Cache: Codable, Equatable {}

    public struct Timing: Codable, Equatable {
        public var blocked: Double
        public var dns: Double
        public var connect: Double
        public var send: Double
        public var wait: Double
        public var receive: Double
        public var ssl: Double
    }
}

extension HAR {
    static func decode(data: Data) throws -> HAR {
        try JSONDecoder().decode(HAR.self, from: data)
    }

    func encoded() throws -> Data {
        try JSONEncoder().encode(self)
    }
}

extension URLRequest {
    init(har: HAR.Request) {
        let url = URL(string: har.url)! // FIXME:
        self.init(url: url)
        httpMethod = har.method
        for header in har.headers {
            setValue(header.value, forHTTPHeaderField: header.name)
        }
        if let postData = har.postData {
            httpBody = postData.text.data(using: .utf8)
        }
    }
}

extension HAR.Request {
    init(request: URLRequest) {
        method = "GET"
        if let method = request.httpMethod {
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
            postData = HAR.PostData(mimeType: mimeType, text: text)
        }
    }
}

internal func parseFormUrlEncoded(_ str: String) -> [(key: String, value: String?)] {
    var components = URLComponents()
    components.query = str
    return components.queryItems?.map { ($0.name, $0.value) } ?? []
}

extension HAR.Param {
    init(_ pair: (key: String, value: String?)) {
        name = pair.key
        value = pair.value
    }
}

extension HAR.PostData {
    init(mimeType: String, text: String) {
        self.mimeType = mimeType
        self.text = text

        if mimeType.hasPrefix("application/x-www-form-urlencoded") {
            params = parseFormUrlEncoded(text).map { HAR.Param($0) }
        }
    }
}

extension HAR.Cookie {
    init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}
