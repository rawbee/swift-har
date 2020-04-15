import HARTesting
import XCTest

final class XCTAttachmentTests: XCTestCase {
    func testAttachment() throws {
        let har = try HAR(data: XCTUnwrap(fixtureData["Safari example.com.har"]))

        XCTAssertEqual(har.attachment.name, "Networking")
        XCTAssertEqual(har.attachment.lifetime, .deleteOnSuccess)
    }
}
