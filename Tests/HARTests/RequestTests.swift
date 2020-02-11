@testable import HAR
import XCTest

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class RequestTests: XCTestCase {
    func testInitParsingUrl() throws {
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

    func testURLRequestGet() throws {
        let url = try XCTUnwrap(URL(string: "http://example.com"))
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        urlRequest.setValue("session=123", forHTTPHeaderField: "Cookie")

        let request = HAR.Request(request: urlRequest)
        XCTAssertEqual(request.method, "GET")
        XCTAssertEqual(request.url.absoluteString, "http://example.com")
        XCTAssertEqual(request.httpVersion, "HTTP/1.1")
        XCTAssert(request.cookies.contains(HAR.Cookie(name: "session", value: "123")))
        XCTAssert(request.headers.contains(HAR.Header(name: "Accept", value: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")))
        XCTAssertEqual(request.headersSize, 111)
        XCTAssertEqual(request.bodySize, -1)
    }

    func testURLRequestPost() throws {
        let url = try XCTUnwrap(URL(string: "http://example.com"))
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = Data("{\"foo\":42}".utf8)

        let request = HAR.Request(request: urlRequest)
        XCTAssertEqual(request.method, "POST")
        XCTAssertEqual(request.url.absoluteString, "http://example.com")
        XCTAssertEqual(request.httpVersion, "HTTP/1.1")
        XCTAssertEqual(request.queryString, [])
        XCTAssertEqual(request.postData?.mimeType, "application/json; charset=UTF-8")
        XCTAssertEqual(request.postData?.text, "{\"foo\":42}")
        XCTAssertEqual(request.headersSize, 65)
        XCTAssertEqual(request.bodySize, 10)
    }

    func testURLRequestBinaryPostJunk() throws {
        let url = try XCTUnwrap(URL(string: "http://example.com"))
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"

        let junk = [UInt32](repeating: 0, count: 255).map { _ in UInt32.random(in: 0 ... 10000) }
        urlRequest.httpBody = Data(bytes: junk, count: 255)

        let request = HAR.Request(request: urlRequest)
        XCTAssertEqual(request.method, "POST")
        XCTAssertNil(request.postData)
        XCTAssertEqual(request.headersSize, 18)
        XCTAssertEqual(request.bodySize, 255)
    }

    func testURLRequestWithFormUrlEncodedBody() throws {
        let url = try XCTUnwrap(URL(string: "http://example.com"))
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = "foo=bar".data(using: .utf8)

        let request = HAR.Request(request: urlRequest)
        XCTAssertEqual(request.method, "POST")
        XCTAssertEqual(request.url.absoluteString, "http://example.com")
        XCTAssertEqual(request.httpVersion, "HTTP/1.1")
        XCTAssertEqual(request.queryString, [])
        XCTAssertEqual(request.postData?.mimeType, "application/x-www-form-urlencoded; charset=UTF-8")
        XCTAssertEqual(request.postData?.text, "foo=bar")
        XCTAssertEqual(request.postData?.params, [HAR.Param(name: "foo", value: "bar")])
        XCTAssertEqual(request.headersSize, 82)
        XCTAssertEqual(request.bodySize, 7)
    }

    func testURLRequestNilUrl() throws {
        let url = try XCTUnwrap(URL(string: "http://example.com"))
        var urlRequest = URLRequest(url: url)
        urlRequest.url = nil

        XCTAssertEqual(urlRequest.url?.absoluteString, nil)

        let request = HAR.Request(request: urlRequest)
        XCTAssertEqual(request.url.absoluteString, "about:blank")
    }

    func testURLRequestDefaultHTTPMethod() throws {
        let url = try XCTUnwrap(URL(string: "http://example.com"))
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = nil

        XCTAssertEqual(urlRequest.url?.absoluteString, "http://example.com")
        XCTAssertEqual(urlRequest.httpMethod, "GET")

        let request = HAR.Request(request: urlRequest)
        XCTAssertEqual(request.method, "GET")
    }

    func testURLRequestFromExampleGETFixture() throws {
        let har = try HAR(data: XCTUnwrap(fixtureData["Safari example.com.har"]))
        let harRequest = try XCTUnwrap(har.log.entries.first).request
        let urlRequest = URLRequest(request: harRequest)

        XCTAssertEqual(urlRequest.httpMethod, "GET")
        XCTAssertEqual(urlRequest.url?.absoluteString, "http://example.com/")
        XCTAssertNil(urlRequest.httpBody)
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "User-Agent"), "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_2) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.4 Safari/605.1.15")
    }

    func testURLRequestFromJSBinPOSTFixture() throws {
        let har = try HAR(data: XCTUnwrap(fixtureData["Safari jsbin.com.har"]))
        let harRequest = try XCTUnwrap(har.log.entries[25...].first).request
        let urlRequest = URLRequest(request: harRequest)

        XCTAssertEqual(urlRequest.httpMethod, "POST")
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://jsbin.com/save")
        XCTAssertEqual(urlRequest.httpBody?.count, 531)
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Content-Type"), "application/x-www-form-urlencoded; charset=UTF-8")
    }

    func testURLRequestFromFixtures() throws {
        for (name, data) in fixtureData {
            let har = try HAR(data: data)

            for entry in har.log.entries {
                let r1 = entry.request
                let request = URLRequest(request: r1)
                let r2 = HAR.Request(request: request)

                XCTAssertEqual(r1.method, r2.method, name)
                XCTAssertEqual(r1.url, r2.url, name)
                XCTAssertEqual(normalizedHeaders(r1.headers), normalizedHeaders(r2.headers), name)
                XCTAssertEqual(r1.postData?.data, r2.postData?.data, name)
            }
        }
    }

    func normalizedHeaders(_ headers: [HAR.Header]) -> [HAR.Header] {
        headers
            .map { HAR.Header(name: $0.name.lowercased(), value: $0.value) }
            .sorted { $0.name < $1.name }
    }
}
