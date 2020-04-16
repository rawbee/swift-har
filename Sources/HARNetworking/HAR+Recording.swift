import Foundation
import HAR

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension HAR {
    // MARK: Recording an HAR

    public typealias RecordResult = Result<Self, Error>

    /// Perform URL Request and create HTTP archive of the request and response.
    public static func record(
        request: URLRequest, completionHandler: @escaping (RecordResult) -> Void
    ) {
        Self.Entry.record(
            request: request,
            completionHandler: {
                completionHandler($0.map { Self(log: Self.Log(entries: [$0])) })
            }
        )
    }

    /// Perform URL Request, create HTTP archive and write encoded archive to file URL.
    public static func record(
        request: URLRequest, to url: URL, transform: @escaping (Self) -> Self = { $0 },
        completionHandler: @escaping (RecordResult) -> Void
    ) {
        record(request: request) { result in
            do {
                let har = transform(try result.get())
                try har.write(to: url)
                completionHandler(.success(har))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }

    /// Attempt to load HAR from file system, otherwise perform request and
    /// write result to file system.
    public static func load(
        contentsOf url: URL, orRecordRequest request: URLRequest,
        transform: @escaping (Self) -> Self = { $0 },
        completionHandler: @escaping (RecordResult) -> Void
    ) {
        do {
            completionHandler(.success(try HAR(contentsOf: url)))
        } catch {
            record(request: request, to: url, transform: transform, completionHandler: completionHandler)
        }
    }
}

extension HAR.Entry {
    // MARK: Recording an Entry

    /// Perform URL Request and create HTTP archive Entry of the request and response.
    public static func record(
        request: URLRequest, completionHandler: @escaping (Result<Self, Error>) -> Void
    ) {
        let session = URLSession(
            configuration: URLSessionConfiguration.ephemeral,
            delegate: TaskDelegate(completionHandler),
            delegateQueue: nil
        )
        session.dataTask(with: request).resume()
    }
}

private class TaskDelegate: NSObject, URLSessionDataDelegate {
    // MARK: Type Aliases

    fileprivate typealias CompletionHandler = (Result<HAR.Entry, Error>) -> Void

    // MARK: Initializers

    fileprivate init(_ completionHandler: @escaping CompletionHandler) {
        self.completionHandler = completionHandler
    }

    // MARK: Instance Properties

    private let completionHandler: CompletionHandler

    private var data: Data = Data()
    private var metric: AnyObject?

    // MARK: Instance Methods

    fileprivate func urlSession(
        _ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data
    ) {
        self.data.append(data)
    }

    fileprivate func urlSession(
        _ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?
    ) {
        if let request = task.currentRequest, let response = task.response as? HTTPURLResponse {
            var entry = HAR.Entry(
                request: HAR.Request(consuming: request),
                response: HAR.Response(response: response, data: data)
            )

#if !os(Linux)
            if #available(iOS 10, macOS 10.12, tvOS 10.0, watchOS 3.0, *) {
                if let metric = self.metric as? URLSessionTaskTransactionMetrics {
                    entry.timings = HAR.Timing(metric: metric)
                    entry.time = entry.timings.total

                    switch metric.networkProtocolName {
                    case "h2":
                        entry.request.httpVersion = "HTTP/2"
                        entry.response.httpVersion = "HTTP/2"
                    case "http/1.1":
                        entry.request.httpVersion = "HTTP/1.1"
                        entry.response.httpVersion = "HTTP/1.1"
                    default:
                        break
                    }
                }
            }
#endif

            completionHandler(.success(entry))
        } else if let error = error {
            completionHandler(.failure(error))
        }
    }
}

#if !os(Linux)
@available(iOS 10, macOS 10.12, tvOS 10.0, watchOS 3.0, *)
extension TaskDelegate {
    // MARK: Instance Methods

    fileprivate func urlSession(
        _ session: URLSession, task: URLSessionTask,
        didFinishCollecting metrics: URLSessionTaskMetrics
    ) {
        // Choose last metric, though there might be more accurate of handling
        // multiple metrics.
        metric = metrics.transactionMetrics.last
    }
}
#endif

#if !os(Linux)
@available(iOS 10, macOS 10.12, tvOS 10.0, watchOS 3.0, *)
extension HAR.Timing {
    // MARK: Initializers

    fileprivate init(metric: URLSessionTaskTransactionMetrics) {
        self.init()

        if let start = metric.fetchStartDate, let end = metric.domainLookupStartDate {
            self.blocked = end.timeIntervalSince(start) * 1000
        }

        if let start = metric.domainLookupStartDate, let end = metric.domainLookupEndDate {
            self.dns = end.timeIntervalSince(start) * 1000
        }

        if let start = metric.connectStartDate, let end = metric.connectEndDate {
            self.connect = end.timeIntervalSince(start) * 1000
        }

        if let start = metric.requestStartDate, let end = metric.requestEndDate {
            self.send = end.timeIntervalSince(start) * 1000
        }

        if let start = metric.requestEndDate, let end = metric.responseStartDate {
            self.wait = end.timeIntervalSince(start) * 1000
        }

        if let start = metric.responseStartDate, let end = metric.responseEndDate {
            self.receive = end.timeIntervalSince(start) * 1000
        }

        if let start = metric.secureConnectionStartDate, let end = metric.secureConnectionEndDate {
            self.ssl = end.timeIntervalSince(start) * 1000
        }
    }
}
#endif
