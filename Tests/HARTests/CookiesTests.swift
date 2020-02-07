@testable import HAR
import XCTest

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class CookiesTests: XCTestCase {
    func testInitFromCookieHeader() {
        XCTAssertEqual(
            HAR.Cookies(fromCookieHeader: "foo=bar"),
            [HAR.Cookie(name: "foo", value: "bar")])
        XCTAssertEqual(
            HAR.Cookies(fromCookieHeader: "foo=bar; bar="),
            [HAR.Cookie(name: "foo", value: "bar"), HAR.Cookie(name: "bar", value: "")])
    }

    func testHTTPCookieInit() throws {
        let url = try XCTUnwrap(URL(string: "http://example.com"))
        let cookie = HTTPCookie(cookie: HAR.Cookie(name: "foo", value: "42"), url: url)
        XCTAssert(cookie != nil)
    }
}
