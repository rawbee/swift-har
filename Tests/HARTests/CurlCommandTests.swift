import XCTest

@testable import HAR

final class CurlCommandTests: XCTestCase {
    override func setUp() {
        _ = fixtureData
    }

    func testInitRequest() throws {
        let har = try HAR(data: XCTUnwrap(fixtureData["Safari jsbin.com.har"]))
        let request = try XCTUnwrap(har.log.entries[25...].first).request

        XCTAssertEqual(
            String(describing: HAR.CurlCommand(request: request)),
            """
            curl 'https://jsbin.com/save' \\
              --request POST \\
              --header 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \\
              --header 'Accept: application/json' \\
              --header 'Accept-Language: en-us' \\
              --header 'Accept-Encoding: gzip, deflate, br' \\
              --header 'Host: jsbin.com' \\
              --header 'Origin: https://jsbin.com' \\
              --header 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_2) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.4 Safari/605.1.15' \\
              --header 'Referer: https://jsbin.com/?html,output' \\
              --header 'Content-Length: 531' \\
              --header 'Connection: keep-alive' \\
              --header 'Cookie: last=https%3A%2F%2Fjsbin.com%2F; session=eyJ2ZXJzaW9uIjoiNC4xLjciLCJjc3JmU2VjcmV0IjoiNWliY3oyLXBMOWZodFdPSzREZFR2VWcwIiwiZmxhc2hDYWNoZSI6e30sInJlZmVyZXIiOiIvbG9naW4ifQ==; session.sig=Ng96KW4oa1ujL6JKhHIB-jPzJcg' \\
              --header 'X-Requested-With: XMLHttpRequest' \\
              --header 'x-csrf-token: mrwblExI-ERMW3vuKeJMLqZA7Zn389jb0EhQ'
            """
        )
    }

    func testCustomStringConvertible() {
        XCTAssertEqual(
            String(
                describing: HAR.CurlCommand(
                    url: URL(string: "http://example.com/")!,
                    headers: [
                        ("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"),
                        ("Host", "example.com"),
                        (
                            "User-Agent",
                            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_3) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.5 Safari/605.1.15"
                        ),
                        ("Accept-Language", "en-us"),
                    ]
                )),
            """
            curl 'http://example.com/' \\
              --header 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \\
              --header 'Host: example.com' \\
              --header 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_3) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.5 Safari/605.1.15' \\
              --header 'Accept-Language: en-us'
            """
        )
    }
}
