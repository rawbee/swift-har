@testable import HAR
import XCTest

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
            let url = try unwrap(URL(string: "http://example.com/path?a=b"))
            let url2 = try unwrap(URL(string: "http://example.com/path?c=d"))

            var request = HAR.Request(method: .get, url: url)

            XCTAssertEqual(request.method, .get)
            XCTAssertEqual(request.url.absoluteString, "http://example.com/path?a=b")
            XCTAssertEqual(request.httpVersion, "HTTP/1.1")
            XCTAssertEqual(request.queryString, [HAR.QueryString(name: "a", value: "b")])
            XCTAssertEqual(request.headers, [])
            XCTAssertNil(request.postData)
            XCTAssertEqual(request.headersSize, 44)
            XCTAssertEqual(request.bodySize, -1)

            request.url = url2
            XCTAssertEqual(request.queryString, [HAR.QueryString(name: "c", value: "d")])
        }

        do {
            let url = try unwrap(URL(string: "http://example.com/path?a=b"))

            var request = HAR.Request(method: .post, url: url)
            request.postData = HAR.PostData(text: "b=c", mimeType: "application/x-www-form-urlencoded")

            XCTAssertEqual(request.method, .post)
            XCTAssertEqual(request.url.absoluteString, "http://example.com/path?a=b")
            XCTAssertEqual(request.httpVersion, "HTTP/1.1")
            XCTAssertEqual(request.queryString, [HAR.QueryString(name: "a", value: "b")])
            XCTAssertEqual(request.headers, [])
            XCTAssertEqual(request.headersSize, 45)
            XCTAssertEqual(request.bodySize, 3)
        }
    }

    func testURLRequest() throws {
        do {
            let url = try unwrap(URL(string: "http://example.com"))
            var request = URLRequest(url: url)
            request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
            request.setValue("session=123", forHTTPHeaderField: "Cookie")

            let harRequest = HAR.Request(request: request)
            XCTAssertEqual(harRequest.method, .get)
            XCTAssertEqual(harRequest.url.absoluteString, "http://example.com")
            XCTAssertEqual(harRequest.httpVersion, "HTTP/1.1")
            XCTAssert(harRequest.cookies.contains(HAR.Cookie(name: "session", value: "123")))
            XCTAssert(harRequest.headers.contains(HAR.Header(name: "Accept", value: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")))
            XCTAssertEqual(harRequest.headersSize, 129)
            XCTAssertEqual(harRequest.bodySize, -1)
        }

        do {
            let url = try unwrap(URL(string: "http://example.com"))
            var request = URLRequest(url: url)
            request.setValue("Content-Type", forHTTPHeaderField: "application/x-www-form-urlencoded; charset=UTF-8")
            request.httpMethod = "POST"
            request.httpBody = "foo=bar".data(using: .utf8)

            let harRequest = HAR.Request(request: request)
            XCTAssertEqual(harRequest.method, .post)
            XCTAssertEqual(harRequest.url.absoluteString, "http://example.com")
            XCTAssertEqual(harRequest.httpVersion, "HTTP/1.1")
            XCTAssertEqual(harRequest.queryString, [])
            XCTAssertEqual(harRequest.postData?.mimeType, "application/x-www-form-urlencoded; charset=UTF-8")
            XCTAssertEqual(harRequest.postData?.text, "foo=bar")
            XCTAssertEqual(harRequest.postData?.params.first, HAR.Param(name: "foo", value: "bar"))
            XCTAssertEqual(harRequest.headersSize, 100)
            XCTAssertEqual(harRequest.bodySize, 7)
        }

        do {
            let har = try HAR(contentsOf: fixtureURL(name: "Safari example.com.har"))
            let harRequest = try unwrap(har.log.entries.first).request
            let request = URLRequest(har: harRequest)
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.absoluteString, "http://example.com/")
            XCTAssertNil(request.httpBody)
            XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_2) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.4 Safari/605.1.15")
        }

        do {
            let har = try HAR(contentsOf: fixtureURL(name: "Safari jsbin.com.har"))
            let harRequest = try unwrap(har.log.entries[25...].first).request
            let request = URLRequest(har: harRequest)
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.absoluteString, "https://jsbin.com/save")
            XCTAssertEqual(request.httpBody?.count, 531)
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/x-www-form-urlencoded; charset=UTF-8")
        }

        do {
            for (_, data) in try loadFixtures() {
                let har = try HAR(data: data)

                for entry in har.log.entries {
                    let request = URLRequest(har: entry.request)
                    let rar = HAR.Request(request: request)
                    XCTAssertEqual(entry.request.method, rar.method)
                    XCTAssertEqual(entry.request.url, rar.url)
                    // FIXME: Fix test
                    // XCTAssertEqual(entry.request.headers, rar.headers)
                    // FIXME: Fix test
                    // XCTAssertEqual(entry.request.queryString, rar.queryString)
                    XCTAssertEqual(entry.request.postData, rar.postData)
                }
            }
        }
    }

    func testPostData() throws {
        let postData = HAR.PostData(text: "foo=1&bar=2&message=Hello%20World&q=duck+duck+go", mimeType: "application/x-www-form-urlencoded")
        XCTAssertEqual(
            postData.params,
            [
                HAR.Param(name: "foo", value: "1"),
                HAR.Param(name: "bar", value: "2"),
                HAR.Param(name: "message", value: "Hello World"),
                HAR.Param(name: "q", value: "duck duck go"),
            ])
    }

    func testContent() throws {
        var content = HAR.Content(text: "foo=bar", mimeType: "multipart/form-content")
        XCTAssertEqual(content.text, "foo=bar")
        XCTAssertEqual(content.size, 7)

        content.text = "foo=bar&baz=qux"
        XCTAssertEqual(content.size, 15)

        content = HAR.Content(text: "PGh0bWw+PGhlYWQ+PC9oZWFkPjxib2R5Lz48L2h0bWw+XG4=", encoding: .base64, mimeType: "text/html; charset=utf-8")
        XCTAssertEqual(content.size, 35)
        XCTAssertEqual(content.data?.count, 35)
        XCTAssertEqual(content.text, "PGh0bWw+PGhlYWQ+PC9oZWFkPjxib2R5Lz48L2h0bWw+XG4=")
        XCTAssertEqual(content.encoding, .base64)
    }

    func testTimings() throws {
        let har = try HAR(contentsOf: fixtureURL(name: "Safari example.com.har"))
        let entry = try unwrap(har.log.entries.first)

        let timing = HAR.Timing(blocked: 0, dns: -1, connect: 15, send: 20, wait: 38, receive: 12, ssl: -1)
        XCTAssertEqual(timing.total, 85)

        var entry2 = HAR.Entry(request: entry.request, response: entry.response)
        XCTAssertEqual(entry2.time, 0)

        entry2.timings = timing
        XCTAssertEqual(entry2.time, 85)
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

    enum TestErrors: Error {
        case nilValue
    }

    func unwrap<T>(_ value: T?) throws -> T {
        guard let value = value else {
            throw TestErrors.nilValue
        }
        return value
    }

    static var allTests = [
        ("testLoadFixtures", testLoadFixtures),
        ("testCodable", testCodable),
        ("testDecodable", testDecodable),
        ("testRequest", testRequest),
        ("testURLRequest", testURLRequest),
        ("testPostData", testPostData),
        ("testContent", testContent),
        ("testTimings", testTimings),
    ]
}
