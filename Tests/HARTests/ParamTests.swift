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

    func testCustomStringConvertible() {
        XCTAssertEqual(
            String(describing: HAR.Param(name: "foo", value: "1")),
            "foo=1")
        XCTAssertEqual(
            String(describing: HAR.Param(name: "foo", value: "1", fileName: "example.pdf", contentType: "application/pdf")),
            #"foo=1; filename="example.pdf"; content-type="application/pdf""#)
    }

    func testCustomDebugStringConvertible() {
        XCTAssertEqual(
            String(reflecting: HAR.Param(name: "foo", value: "1")),
            "HAR.Param { foo=1 }")
        XCTAssertEqual(
            String(reflecting: HAR.Param(name: "foo", value: "1", fileName: "example.pdf", contentType: "application/pdf")),
            #"HAR.Param { foo=1; filename="example.pdf"; content-type="application/pdf" }"#)
    }
}
