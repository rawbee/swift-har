@testable import HAR
import XCTest

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class HARTests: XCTestCase {
    func testCodable() throws {
        for (name, data) in fixtureData {
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
        let har = try HAR(data: XCTUnwrap(fixtureData["Safari example.com.har"]))

        XCTAssertEqual(har.log.version, "1.2")
        XCTAssertEqual(har.log.creator.name, "WebKit Web Inspector")
        XCTAssertEqual(har.log.pages?.first?.title, "http://example.com/")
        XCTAssertEqual(har.log.entries.first?.request.url.absoluteString, "http://example.com/")
        XCTAssertEqual(har.log.entries.first?.response.statusText, "OK")
    }

    func testRecord() throws {
        let url = try XCTUnwrap(URL(string: "http://example.com/"))
        let request = URLRequest(url: url)

        let har = try HAR.record(request: request)

        guard let entry = har.log.entries.first else {
            XCTFail("no entries")
            return
        }

        XCTAssertEqual(entry.request.method, "GET")
        XCTAssertEqual(entry.request.url.absoluteString, "http://example.com/")
        XCTAssertGreaterThan(entry.request.headersSize, 0)
        XCTAssertEqual(entry.request.bodySize, 0)

        XCTAssertEqual(entry.response.status, 200)
        XCTAssertEqual(entry.response.statusText, "OK")
        XCTAssertGreaterThan(entry.response.headersSize, 0)
        XCTAssertGreaterThan(entry.response.bodySize, 0)

#if !os(Linux)
        XCTAssertGreaterThan(entry.time, 0)
        XCTAssertGreaterThan(entry.timings.send, 0)
        XCTAssertGreaterThan(entry.timings.wait, 0)
        XCTAssertGreaterThan(entry.timings.receive, 0)
#endif
    }
}
