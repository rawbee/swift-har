@testable import HAR
import XCTest

final class PostDataTests: XCTestCase {
    let formDataText = """
    ------WebKitFormBoundary
    Content-Disposition: form-data; name="name"
    Steve Jobs
    ------WebKitFormBoundary
    Content-Disposition: form-data; name="upload"; filename="upload.pdf"
    Content-Type: application/pdf
    ------WebKitFormBoundaryJ8ZeKCKRN4jiAZ8G--
    """

    func testEquatable() {
        XCTAssertEqual(
            HAR.PostData(mimeType: "application/x-www-form-urlencoded; charset=UTF-8", params: [HAR.Param(name: "foo", value: "1")], text: "foo=1"),
            HAR.PostData(mimeType: "application/x-www-form-urlencoded; charset=UTF-8", params: [HAR.Param(name: "foo", value: "1")], text: "foo=1"))
        XCTAssertNotEqual(
            HAR.PostData(mimeType: "application/x-www-form-urlencoded; charset=UTF-8", params: [HAR.Param(name: "foo", value: "1")], text: "foo=1"),
            HAR.PostData(mimeType: "application/x-www-form-urlencoded; charset=UTF-8", params: [HAR.Param(name: "bar", value: "2")], text: "bar=2"))

        XCTAssertEqual(
            HAR.PostData(mimeType: "multipart/form-data; boundary=----WebKitFormBoundary", params: [], text: formDataText),
            HAR.PostData(mimeType: "multipart/form-data; boundary=----WebKitFormBoundary", params: [], text: formDataText))
    }
}
