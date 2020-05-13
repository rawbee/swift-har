import Foundation
import HAR
import HARNetworking

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension HAR.MockURLProtocol {
    public static var caller: (file: StaticString, line: UInt)?
}
