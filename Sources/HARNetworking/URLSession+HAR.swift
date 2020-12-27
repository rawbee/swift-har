import HAR

import struct Foundation.Data
import class Foundation.NSObject
import struct Foundation.URL

#if canImport(FoundationNetworking)
import class FoundationNetworking.HTTPURLResponse
import struct FoundationNetworking.URLRequest
import class FoundationNetworking.URLSession
import protocol FoundationNetworking.URLSessionDataDelegate
import class FoundationNetworking.URLSessionDataTask
import class FoundationNetworking.URLSessionTask
#else
import class Foundation.HTTPURLResponse
import struct Foundation.URLRequest
import class Foundation.URLSession
import protocol Foundation.URLSessionDataDelegate
import class Foundation.URLSessionDataTask
import class Foundation.URLSessionTask
#endif

public typealias URLSessionArchiveTask = URLSessionDataTask

public extension URLSession {
    // MARK: Recording an Entry

    /// Perform URL Request and create HTTP archive Entry of the request and response.
    func archiveTask(
        with request: URLRequest,
        appendingTo fileURL: URL? = nil,
        transform: @escaping (HAR.Entry) -> HAR.Entry = { $0 },
        completionHandler: @escaping (Result<HAR.Entry, Error>) -> Void
    ) -> URLSessionArchiveTask {
        let session = URLSession(
            configuration: self.configuration,
            delegate: TaskDelegate(fileURL, transform, completionHandler),
            delegateQueue: self.delegateQueue
        )

        var bufferedRequest = request
        bufferedRequest.bufferHTTPBodyStream()

        return session.dataTask(with: bufferedRequest)
    }
}

private class TaskDelegate: NSObject, URLSessionDataDelegate {
    // MARK: Type Aliases

    fileprivate typealias Transform = (HAR.Entry) -> HAR.Entry
    fileprivate typealias CompletionHandler = (Result<HAR.Entry, Error>) -> Void

    // MARK: Initializers

    fileprivate init(
        _ fileURL: URL?,
        _ transform: @escaping Transform,
        _ completionHandler: @escaping CompletionHandler
    ) {
        self.fileURL = fileURL
        self.transform = transform
        self.completionHandler = completionHandler
    }

    // MARK: Instance Properties

    private let fileURL: URL?
    private let transform: Transform
    private let completionHandler: CompletionHandler

    private var data = Data()
    private var metric: AnyObject?

    // MARK: Instance Methods

    fileprivate func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    ) {
        self.data.append(data)
    }

    fileprivate func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
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
            let transformedEntry = transform(entry)

            if let fileURL = self.fileURL {
                do {
                    try transformedEntry.append(to: fileURL)
                } catch {
                    completionHandler(.failure(error))
                    return
                }
            }

            completionHandler(.success(transformedEntry))
        } else if let error = error {
            completionHandler(.failure(error))
        }
    }
}

#if !os(Linux)
import class Foundation.URLSessionTaskMetrics
import class Foundation.URLSessionTaskTransactionMetrics

@available(iOS 10, macOS 10.12, tvOS 10.0, watchOS 3.0, *)
extension TaskDelegate {
    // MARK: Instance Methods

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
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
fileprivate extension HAR.Timing {
    // MARK: Initializers

    init(metric: URLSessionTaskTransactionMetrics) {
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
