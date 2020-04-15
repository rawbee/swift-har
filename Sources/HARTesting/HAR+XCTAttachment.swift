#if !os(Linux)
import HAR
import XCTest

extension HAR {
    public var attachment: XCTAttachment {
        do {
            let data = try encoded()
            let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.json")
            attachment.name = "Networking"
            attachment.lifetime = .deleteOnSuccess
            return attachment
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
#endif
