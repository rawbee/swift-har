@testable import HAR
import XCTest

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class HARTests: XCTestCase {
    func testLoadFixtures() throws {
        XCTAssertGreaterThan(try loadFixtures().count, 1)
    }

    func testCodable() throws {
        for (name, data) in try loadFixtures() {
            do {
                let har = try HAR(data: data)
                _ = try har.encoded()
            } catch {
                XCTAssertNil(error, "\(name) failed encoding.")
                throw error
            }
        }
    }

    func testDecodable() throws {
        let har = try HAR(contentsOf: fixtureURL(name: "Safari example.com.har"))

        XCTAssertEqual(har.log.version, "1.2")
        XCTAssertEqual(har.log.creator.name, "WebKit Web Inspector")
        XCTAssertEqual(har.log.pages?.first?.title, "http://example.com/")
        XCTAssertEqual(har.log.entries.first?.request.url.absoluteString, "http://example.com/")
        XCTAssertEqual(har.log.entries.first?.response.statusText, "OK")
    }

    func testRequest() throws {
        do {
            let url = try XCTUnwrap(URL(string: "http://example.com/path?a=b"))
            let request = HAR.Request(method: "GET", url: url)

            XCTAssertEqual(request.method, "GET")
            XCTAssertEqual(request.url.absoluteString, "http://example.com/path?a=b")
            XCTAssertEqual(request.httpVersion, "HTTP/1.1")
            XCTAssertEqual(request.queryString, [HAR.QueryString(name: "a", value: "b")])
            XCTAssertEqual(request.headers, [])
            XCTAssertNil(request.postData)
            XCTAssertEqual(request.headersSize, 22)
            XCTAssertEqual(request.bodySize, -1)
        }
    }

    func testURLRequest() throws {
        do {
            let url = try XCTUnwrap(URL(string: "http://example.com"))
            var request = URLRequest(url: url)
            request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
            request.setValue("session=123", forHTTPHeaderField: "Cookie")

            let harRequest = HAR.Request(request: request)
            XCTAssertEqual(harRequest.method, "GET")
            XCTAssertEqual(harRequest.url.absoluteString, "http://example.com")
            XCTAssertEqual(harRequest.httpVersion, "HTTP/1.1")
            XCTAssert(harRequest.cookies.contains(HAR.Cookie(name: "session", value: "123")))
            XCTAssert(harRequest.headers.contains(HAR.Header(name: "Accept", value: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")))
            XCTAssertEqual(harRequest.headersSize, 111)
            XCTAssertEqual(harRequest.bodySize, -1)
        }

        do {
            let url = try XCTUnwrap(URL(string: "http://example.com"))
            var request = URLRequest(url: url)
            request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = "{\"foo\":42}".data(using: .utf8)

            let rar = HAR.Request(request: request)
            XCTAssertEqual(rar.method, "POST")
            XCTAssertEqual(rar.url.absoluteString, "http://example.com")
            XCTAssertEqual(rar.httpVersion, "HTTP/1.1")
            XCTAssertEqual(rar.queryString, [])
            XCTAssertEqual(rar.postData?.mimeType, "application/json; charset=UTF-8")
            XCTAssertEqual(rar.postData?.text, "{\"foo\":42}")
            XCTAssertEqual(rar.headersSize, 65)
            XCTAssertEqual(rar.bodySize, 10)
        }

        do {
            let url = try XCTUnwrap(URL(string: "http://example.com"))
            var request = URLRequest(url: url)
            request.httpMethod = "POST"

            let junk = [UInt32](repeating: 0, count: 255).map { _ in UInt32.random(in: 0 ... 10000) }
            request.httpBody = Data(bytes: junk, count: 255)

            let rar = HAR.Request(request: request)
            XCTAssertEqual(rar.method, "POST")
            XCTAssertNil(rar.postData)
            XCTAssertEqual(rar.headersSize, 18)
            XCTAssertEqual(rar.bodySize, -1)
        }

        do {
            let url = try XCTUnwrap(URL(string: "http://example.com"))
            var request = URLRequest(url: url)
            request.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = "foo=bar".data(using: .utf8)

            let harRequest = HAR.Request(request: request)
            XCTAssertEqual(harRequest.method, "POST")
            XCTAssertEqual(harRequest.url.absoluteString, "http://example.com")
            XCTAssertEqual(harRequest.httpVersion, "HTTP/1.1")
            XCTAssertEqual(harRequest.queryString, [])
            XCTAssertEqual(harRequest.postData?.mimeType, "application/x-www-form-urlencoded; charset=UTF-8")
            XCTAssertEqual(harRequest.postData?.text, "foo=bar")
            XCTAssertEqual(harRequest.postData?.params.first, HAR.Param(name: "foo", value: "bar"))
            XCTAssertEqual(harRequest.headersSize, 82)
            XCTAssertEqual(harRequest.bodySize, 7)
        }

        do {
            let url = try XCTUnwrap(URL(string: "http://example.com"))

            var req: URLRequest
            var rar: HAR.Request

            req = URLRequest(url: url)
            req.httpMethod = nil
            XCTAssertEqual(req.url?.absoluteString, "http://example.com")
            XCTAssertEqual(req.httpMethod, "GET")
            rar = HAR.Request(request: req)
            XCTAssertEqual(rar.method, "GET")
        }

        do {
            let har = try HAR(contentsOf: fixtureURL(name: "Safari example.com.har"))
            let harRequest = try XCTUnwrap(har.log.entries.first).request
            let request = URLRequest(request: harRequest)
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.absoluteString, "http://example.com/")
            XCTAssertNil(request.httpBody)
            XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_2) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.4 Safari/605.1.15")
        }

        do {
            let har = try HAR(contentsOf: fixtureURL(name: "Safari jsbin.com.har"))
            let harRequest = try XCTUnwrap(har.log.entries[25...].first).request
            let request = URLRequest(request: harRequest)
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.absoluteString, "https://jsbin.com/save")
            XCTAssertEqual(request.httpBody?.count, 531)
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/x-www-form-urlencoded; charset=UTF-8")
        }

        do {
            for (_, data) in try loadFixtures() {
                let har = try HAR(data: data)

                for entry in har.log.entries {
                    let request = URLRequest(request: entry.request)
                    let rar = HAR.Request(request: request)
                    XCTAssertEqual(entry.request.method, rar.method)
                    XCTAssertEqual(entry.request.url, rar.url)
                    XCTAssertEqual(normalizedHeaders(entry.request.headers), normalizedHeaders(rar.headers))
                    XCTAssertEqual(entry.request.postData?.text, rar.postData?.text)
                }
            }
        }
    }

    func testURLResponse() throws {
        do {
            for (_, data) in try loadFixtures() {
                let har = try HAR(data: data)

                for entry in har.log.entries {
                    let response = HTTPURLResponse(url: entry.request.url, response: entry.response)
                    let rar = HAR.Response(response: response, data: entry.response.content.data)
                    XCTAssertEqual(entry.response.status, rar.status)
                    XCTAssertEqual(normalizedHeaders(entry.response.headers), normalizedHeaders(rar.headers))
                    // XCTAssertEqual(entry.response.content.text, rar.content.text)
                }
            }
        }
    }

    func normalizedHeaders(_ headers: [HAR.Header]) -> [HAR.Header] {
        headers
            // FIXME: Multiple Set-Cookie is broken
            .filter { $0.name.lowercased() != "set-cookie" }
            .map { HAR.Header(($0.name.lowercased(), $0.value)) }
            .sorted { $0.name < $1.name }
    }

    func testCookie() throws {
        let url = try XCTUnwrap(URL(string: "http://example.com"))

        XCTAssertEqual(HAR.Cookies(fromCookieHeader: "foo=bar"), [HAR.Cookie(name: "foo", value: "bar")])
        XCTAssertEqual(HAR.Cookies(fromCookieHeader: "foo=bar; bar="), [HAR.Cookie(name: "foo", value: "bar"), HAR.Cookie(name: "bar", value: "")])

        XCTAssertNotEqual(HTTPCookie(cookie: HAR.Cookie(name: "foo", value: "42"), url: url), nil)
    }

    func testHeaders() throws {
        let url = try XCTUnwrap(URL(string: "http://example.com"))

        var req: HAR.Request

        req = HAR.Request(method: "POST", url: url)
        req.headers = [
            HAR.Header(("Accept", "*/*")),
            HAR.Header(("Content-Type", "application/json")),
        ]
        XCTAssertEqual(req.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(req.value(forHTTPHeaderField: "Content-type"), "application/json")
        XCTAssertEqual(req.value(forHTTPHeaderField: "content-type"), "application/json")
        XCTAssertNil(req.value(forHTTPHeaderField: "type"))
    }

    func testContent() throws {
        var content = HAR.Content(text: "foo=bar", mimeType: "multipart/form-content")
        XCTAssertEqual(content.text, "foo=bar")
        XCTAssertEqual(content.size, 7)

        content = HAR.Content(text: "PGh0bWw+PGhlYWQ+PC9oZWFkPjxib2R5Lz48L2h0bWw+XG4=", encoding: "base64", mimeType: "text/html; charset=utf-8")
        XCTAssertEqual(content.size, 35)
        XCTAssertEqual(content.data?.count, 35)
        XCTAssertEqual(content.text, "PGh0bWw+PGhlYWQ+PC9oZWFkPjxib2R5Lz48L2h0bWw+XG4=")
        XCTAssertEqual(content.encoding, "base64")
    }

    func testTimings() throws {
        let har = try HAR(contentsOf: fixtureURL(name: "Safari example.com.har"))
        let entry = try XCTUnwrap(har.log.entries.first)

        let timing = HAR.Timing(blocked: 0, dns: -1, connect: 15, send: 20, wait: 38, receive: 12, ssl: -1)
        XCTAssertEqual(timing.total, 85)

        let entry2 = HAR.Entry(request: entry.request, response: entry.response)
        XCTAssertEqual(entry2.time, 0)

        // entry2.timings = timing
        // XCTAssertEqual(entry2.time, 85)
    }

    func testRecord() throws {
        let url = try XCTUnwrap(URL(string: "http://example.com"))
        let request = URLRequest(url: url)

        let har = try HAR.record(request: request)

        guard let entry = har.log.entries.first else {
            XCTFail("no entries")
            return
        }

        XCTAssertGreaterThan(entry.time, 0)
        XCTAssertGreaterThan(entry.timings.receive, 0)

        XCTAssertEqual(entry.request.url.absoluteString, "http://example.com")
        XCTAssertEqual(entry.response.status, 200)
    }

    var fixtureURL: URL {
        var url = URL(fileURLWithPath: #file)
        url.appendPathComponent("../../Fixtures")
        url.standardize()
        return url
    }

    func fixtureURL(name: String) -> URL {
        fixtureURL.appendingPathComponent(name)
    }

    func loadFixtures() throws -> [String: Data] {
        var fixtures: [String: Data] = [:]
        for name in try FileManager.default.contentsOfDirectory(atPath: fixtureURL.path) {
            fixtures[name] = try Data(contentsOf: fixtureURL(name: name))
        }
        return fixtures
    }
}
