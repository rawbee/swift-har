import XCTest
@testable import HAR

final class HARTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(HAR().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
