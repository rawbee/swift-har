@testable import HAR
import XCTest

final class ParamTests: XCTestCase {
    func testEquatable() {
        XCTAssertEqual(HAR.Param(name: "foo", value: "1"), HAR.Param(name: "foo", value: "1"))
        XCTAssertNotEqual(HAR.Param(name: "foo", value: "1"), HAR.Param(name: "foo", value: "2"))
        XCTAssertNotEqual(HAR.Param(name: "foo", value: "1"), HAR.Param(name: "bar", value: "1"))
        XCTAssertNotEqual(HAR.Param(name: "foo", value: "1"), HAR.Param(name: "bar", value: "2"))
    }

    func testHashable() {
        let set = Set([
            HAR.Param(name: "foo", value: "1"),
            HAR.Param(name: "foo", value: "1"),
            HAR.Param(name: "foo", value: "2"),
        ])
        XCTAssertEqual(set.count, 2)
    }
}
