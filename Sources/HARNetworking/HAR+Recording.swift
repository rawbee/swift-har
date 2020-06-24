import HAR

import struct Foundation.URL

#if canImport(FoundationNetworking)
import struct FoundationNetworking.URLRequest
import class FoundationNetworking.URLSession
#else
import struct Foundation.URLRequest
import class Foundation.URLSession
#endif

extension HAR {
    // MARK: Recording an HAR

    public typealias RecordResult = Result<Self, Error>

    /// Perform URL Request and create HTTP archive of the request and response.
    public static func record(
        request: URLRequest,
        to url: URL? = nil,
        transform: @escaping (HAR.Entry) -> HAR.Entry = { $0 },
        completionHandler: @escaping (RecordResult) -> Void
    ) {
        let session = URLSession(configuration: .ephemeral)
        let task = session.archiveTask(with: request, appendingTo: url, transform: transform) {
            completionHandler($0.map { .init(entry: $0) })
        }
        task.resume()
    }

    /// Attempt to load HAR from file system, otherwise perform request and
    /// write result to file system.
    public static func load(
        contentsOf url: URL,
        orRecordRequest request: URLRequest,
        completionHandler: @escaping (RecordResult) -> Void,
        transform: @escaping (HAR.Entry) -> HAR.Entry = { $0 }
    ) {
        do {
            completionHandler(.success(try HAR(contentsOf: url)))
        } catch {
            record(
                request: request,
                to: url,
                transform: transform,
                completionHandler: completionHandler
            )
        }
    }
}
