@testable import HAR
import XCTest

final class HARTests: XCTestCase {
    func testLoadFixtures() {
        XCTAssertGreaterThan(fixtures.count, 1)
    }

    enum NormalizeJSON: Error {
        case unavailable
        case decodingError
    }

    func stripPrivateKeys(_ value: Any) -> Any {
        switch value {
        case let dict as [String: Any]:
            return dict.mapValues { stripPrivateKeys($0) }.filter { !$0.key.starts(with: "_") }
        case let array as [Any]:
            return array.map { stripPrivateKeys($0) }
        default:
            return value
        }
    }

    func normalizeJSON(data: Data) throws -> String {
        guard #available(macOS 10.13, *) else {
            throw NormalizeJSON.unavailable
        }

        let jsonObject = stripPrivateKeys(try JSONSerialization.jsonObject(with: data))
        let jsonData = try JSONSerialization.data(
            withJSONObject: jsonObject,
            options: [
                .sortedKeys,
                .prettyPrinted,
            ])

        guard let jsonString = String(bytes: jsonData, encoding: .utf8) else {
            throw NormalizeJSON.decodingError
        }

        return jsonString
    }

    func testCodable() throws {
        let decoder = JSONDecoder()

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        for (name, data) in fixtures {
            do {
                let har = try decoder.decode(HAR.self, from: data)

                let data2 = try encoder.encode(har)
                let har2 = try decoder.decode(HAR.self, from: data2)

                XCTAssertEqual(har, har2, "\(name) did not encode properly.")
                XCTAssertEqual(try normalizeJSON(data: data), try normalizeJSON(data: data2), "\(name) did not serialize to same JSON.")
            } catch {
                XCTAssertNil(error, "\(name) failed encoding.")
                throw error
            }
        }
    }

    func testDecodable() throws {
        let data = fixture(name: "example.com.har")

        let decoder = JSONDecoder()
        let har = try decoder.decode(HAR.self, from: data)

        XCTAssertEqual(har.log.version, "1.2")
        XCTAssertEqual(har.log.creator.name, "WebKit Web Inspector")
        XCTAssertEqual(har.log.pages?.first?.title, "http://example.com/")
        XCTAssertEqual(har.log.entries.first?.request.url, "http://example.com/")
        XCTAssertEqual(har.log.entries.first?.response.statusText, "OK")
    }

    var fixtureURL: URL {
        var url = URL(fileURLWithPath: #file)
        url.appendPathComponent("../../Fixtures")
        url.standardize()
        return url
    }

    var fixtures: [String: Data] {
        var fixtures: [String: Data] = [:]
        for name in try! FileManager.default.contentsOfDirectory(atPath: fixtureURL.path) {
            fixtures[name] = fixture(name: name)
        }
        return fixtures
    }

    func fixture(name: String) -> Data {
        try! Data(contentsOf: fixtureURL.appendingPathComponent(name))
    }

    static var allTests = [
        ("testLoadFixtures", testLoadFixtures),
        ("testCodable", testCodable),
        ("testDecodable", testDecodable),
    ]
}
