import struct Foundation.Data
import struct Foundation.Date
import struct Foundation.URL

extension HAR {
    /// This object represents an array with all exported HTTP requests. Sorting entries
    /// by `startedDateTime` (starting from the oldest) is preferred way how to export
    /// data since it can make importing faster. However the reader application should
    /// always make sure the array is sorted (if required for the import).
    public struct Entry: Equatable, Hashable, Codable {
        // MARK: Properties

        /// Reference to the parent page. Leave out this field if the application does
        /// not support grouping by pages.
        public var pageref: String?

        /// Date and time stamp of the request start.
        public var startedDateTime: Date

        /// Total elapsed time of the request in milliseconds. This is the sum of all
        /// timings available in the timings object (i.e. not including -1 values) .
        ///
        /// - Invariant: The time value for the request must be equal to the sum of the
        /// timings supplied in this section (excluding any -1 values).
        public var time: Double

        /// Detailed info about the request.
        public var request: Request

        /// Detailed info about the response.
        public var response: Response

        /// Info about cache usage.
        public var cache: Cache

        /// Detailed timing info about request/response round trip.
        public var timings: Timing

        /// IP address of the server that was connected (result of DNS resolution).
        ///
        /// - Version: 1.2
        public var serverIPAddress: String?

        /// Unique ID of the parent TCP/IP connection, can be the client or server port
        /// number. Note that a port number doesn't have to be unique identifier in cases
        /// where the port is shared for more connections. If the port isn't available
        /// for the application, any other unique connection ID can be used instead (e.g.
        /// connection index). Leave out this field if the application doesn't support
        /// this info.
        ///
        /// - Version: 1.2
        public var connection: String?

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?

        // MARK: Computed Properties

        /// Computed `time` from timings.
        public var computedTime: Double {
            timings.total
        }

        // MARK: Initializers

        /// Create entry.
        public init(
            pageref: String? = nil,
            startedDateTime: Date = .init(),
            time: Double = 0,
            request: Request,
            response: Response,
            cache: Cache = .init(),
            timings: Timing = .init(),
            serverIPAddress: String? = nil,
            connection: String? = nil,
            comment: String? = nil
        ) {
            self.pageref = pageref
            self.startedDateTime = startedDateTime
            self.time = time
            self.request = request
            self.response = response
            self.cache = cache
            self.timings = timings
            self.serverIPAddress = serverIPAddress
            self.connection = connection
            self.comment = comment
        }

        public func append(to url: URL, options: Data.WritingOptions = []) throws {
            var har = try HAR(contentsOf: url)
            har.log.entries.append(self)
            try har.write(to: url, options: options)
        }
    }

    /// Array of Entry objects.
    public typealias Entries = [Entry]
}
