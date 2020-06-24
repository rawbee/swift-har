import struct Foundation.Data
import struct Foundation.Date
import class Foundation.DateFormatter
import class Foundation.FileManager
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder
import struct Foundation.TimeZone
import struct Foundation.URL

/// HTTP Archive
/// - Version: 1.2
///
/// http://www.softwareishard.com/blog/har-12-spec/
public struct HAR: Equatable, Hashable, Codable {
    // MARK: Properties

    /// Log data root.
    public var log: Log

    // MARK: Initializers

    /// Create HAR.
    public init(log: Log) {
        self.log = log
    }

    /// Create HAR from a single entry.
    public init(entry: Entry) {
        self.init(log: Log(entries: [entry]))
    }

    // MARK: Encoding and Decoding

    /// Creates a `HAR` from the contents of a file URL.
    ///
    /// - Parameter url: Path to `.har` file.
    public init(contentsOf url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    /// Writes the ecoded HAR to a location.
    public func write(to url: URL, options: Data.WritingOptions = []) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil
        )
        try encoded().write(to: url, options: options)
    }

    /// Initialize ISO 8601 date formatter.
    ///
    /// Uses the format `YYYY-MM-DDThh:mm:ss.sTZD` to return a date such as
    private static let jsonDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSZZZZZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    /// Creates a `HAR` from JSON `Data`.
    ///
    /// - Parameter data: UTF-8 JSON data.
    public init(data: Data) throws {
        let decoder = JSONDecoder()

        decoder.dateDecodingStrategy = .custom { (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)

            if let date = Self.jsonDateFormatter.date(from: dateStr) {
                return date
            }

            throw Swift.DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "invalid date: \(dateStr)"
            )
        }

        self = try decoder.decode(Self.self, from: data)
    }

    /// Returns a HAR encoded as JSON `Data`.
    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .formatted(Self.jsonDateFormatter)
        return try encoder.encode(self)
    }
}
