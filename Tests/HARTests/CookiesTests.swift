import XCTest

@testable import HAR

final class CookiesTests: XCTestCase {
    func testInitFromCookieHeader() {
        XCTAssertEqual(
            HAR.Cookies(fromCookieHeader: "foo=bar"),
            [HAR.Cookie(name: "foo", value: "bar")]
        )
        XCTAssertEqual(
            HAR.Cookies(fromCookieHeader: "foo=bar; bar="),
            [HAR.Cookie(name: "foo", value: "bar"), HAR.Cookie(name: "bar", value: "")]
        )
    }
}
