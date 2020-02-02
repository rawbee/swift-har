@testable import HAR
import XCTest

final class ParamsTests: XCTestCase {
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
            String(describing: HAR.Param(name: "foo", fileName: "example.pdf", contentType: "application/pdf")),
            #"foo=@example.pdf;type=application/pdf"#)
    }

    func testCustomDebugStringConvertible() {
        XCTAssertEqual(
            String(reflecting: HAR.Param(name: "foo", value: "1")),
            "HAR.Param { foo=1 }")
        XCTAssertEqual(
            String(reflecting: HAR.Param(name: "foo", value: "1", fileName: "example.pdf", contentType: "application/pdf")),
            #"HAR.Param { foo=@example.pdf;type=application/pdf }"#)
    }

    func testDecodable() throws {
        let json = """
            {
                "name": "foo",
                "value": "42"
            }
        """

        let param = try JSONDecoder().decode(HAR.Param.self, from: Data(json.utf8))
        XCTAssertEqual(
            param,
            HAR.Param(name: "foo", value: "42"))
    }

    func testEncodable() throws {
        let data = try JSONEncoder().encode(HAR.Param(name: "foo", value: "42"))
        let json = String(decoding: data, as: UTF8.self)

        XCTAssertEqual(
            json,
            #"{"name":"foo","value":"42"}"#)
    }
}
