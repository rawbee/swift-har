@testable import HAR
import XCTest

final class HARTests: XCTestCase {
    func testCodable() {
        XCTAssertEqual(fixtures.count, 1)
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
        ("testCodable", testCodable),
    ]
}
