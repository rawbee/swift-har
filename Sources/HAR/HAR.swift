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
        public var entries: [Entry]
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
        public var cookies: [Cookie]
        public var headers: [Header]
        public var queryString: [QueryString]
        public var postData: PostData?
        public var headersSize: Int
        public var bodySize: Int

        init(_ request: URLRequest) {
            method = "GET"
            if let method = request.httpMethod {
                self.method = method
            }

            url = "about:blank"
            if let url = request.url {
                self.url = url.absoluteString
            }

            httpVersion = "HTTP/1.1"

            // TODO:
            cookies = []

            headers = []
            if let headers = request.allHTTPHeaderFields {
                for (name, value) in headers {
                    self.headers.append(Header(name: name, value: value))
                }
            }

            // TODO:
            queryString = []

            // TODO:
            postData = nil

            // TODO:
            headersSize = -1
            bodySize = -1
        }
    }

    public struct Response: Codable, Equatable {
        public var status: Int
        public var statusText: String
        public var httpVersion: String
        public var cookies: [Cookie]
        public var headers: [Header]
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
        public var params: [Param]
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

    func encoded() throws -> Data {
        try JSONEncoder().encode(self)
    }
}
