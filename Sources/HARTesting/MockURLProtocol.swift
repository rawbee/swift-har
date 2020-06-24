import HAR
import HARNetworking

extension HAR.MockURLProtocol {
    public static var caller: (file: StaticString, line: UInt)?
}
