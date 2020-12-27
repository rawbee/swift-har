import struct Foundation.NSRange
import class Foundation.NSRegularExpression

public extension HAR {
    /// This object contains list of all headers (used in `Request` and `Response`
    /// objects).
    struct Header: Equatable, Comparable, Hashable, Codable, CustomStringConvertible,
        CustomDebugStringConvertible
    {
        // MARK: Properties

        /// The header name.
        public var name: String

        /// The header value.
        public var value: String

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?

        // MARK: Initializers

        /// Create header.
        public init(name: String, value: String, comment: String? = nil) {
            self.name = name
            self.value = value
            self.comment = comment
        }

        // MARK: Comparing Headers

        internal enum Group: Int, Comparable {
            case general
            case request
            case response
            case entity

            init(name: String) {
                switch name {
                case "Cache-Control", "Connection", "Date", "Pragma", "Trailer", "Transfer-Encoding",
                     "Upgrade", "Via", "Warning":
                    self = .general
                case "Accept", "Accept-Charset", "Accept-Encoding", "Accept-Language", "Authorization",
                     "Expect", "From", "Host", "If-Match", "If-Modified-Since", "If-None-Match", "If-Range",
                     "If-Unmodified-Since", "Max-Forwards", "Proxy-Authorization", "Range", "Referer", "TE",
                     "User-Agent":
                    self = .request
                case "Accept-Ranges", "Age", "ETag", "Location", "Proxy-Authenticate", "Retry-After",
                     "Server", "Vary", "WWW-Authenticate":
                    self = .response
                case "Allow", "Content-Encoding", "Content-Language", "Content-Length", "Content-Location",
                     "Content-MD5", "Content-Range", "Content-Type", "Expires", "Last-Modified":
                    self = .entity
                default:
                    self = .entity
                }
            }

            static func <(lhs: Self, rhs: Self) -> Bool {
                lhs.rawValue < rhs.rawValue
            }
        }

        internal var group: Group {
            Group(name: name)
        }

        /// Returns a Boolean value indicating whether two headers are equal.
        ///
        /// Header names are case-insensitive.
        public static func ==(lhs: Self, rhs: Self) -> Bool {
            lhs.name.caseInsensitiveCompare(rhs.name) == .orderedSame && lhs.value == rhs.value
                && lhs.comment == rhs.comment
        }

        public static func <(lhs: Self, rhs: Self) -> Bool {
            if lhs.group != rhs.group {
                return lhs.group < rhs.group
            } else {
                return lhs.name < rhs.name
            }
        }

        /// Test if header name matches case-insensitive name.
        public func isNamed(_ name: String) -> Bool {
            self.name.caseInsensitiveCompare(name) == .orderedSame
        }

        /// Test if header name matches Regular Expression.
        public func isNamed(_ pattern: NSRegularExpression) -> Bool {
            let range = NSRange(name.startIndex ..< name.endIndex, in: name)
            return pattern.firstMatch(in: name, options: [], range: range) != nil
        }

        /// Hashes the lower case name of the header by feeding them into the given hasher.
        public func hash(into hasher: inout Hasher) {
            hasher.combine(name.lowercased())
        }

        // MARK: Describing Headers

        /// A human-readable description for the data.
        public var description: String {
            "\(name): \(value)"
        }

        /// A human-readable debug description for the data.
        public var debugDescription: String {
            "HAR.Header { \(description) }"
        }
    }

    /// Array of Header objects.
    typealias Headers = [Header]
}

public extension HAR.Headers {
    // MARK: Computed Properties

    var headersAsDictionary: [String: String] {
        reduce(into: [:]) { result, header in
            if result[header.name] == nil {
                result[header.name] = header.value
            } else {
                result[header.name]! += (", " + header.value)
            }
        }
    }

    // MARK: Instance Methods

    /// Find all header values for name.
    ///
    /// Header names are case-insensitive.
    ///
    /// - Parameter name: The HTTP Header name.
    func values(forName name: String) -> [String] {
        filter { $0.isNamed(name) }.map { $0.value }
    }

    /// Find first header value for name.
    ///
    /// Header names are case-insensitive.
    ///
    /// - Parameter name: The HTTP Header name.
    func value(forName name: String) -> String? {
        values(forName: name).first
    }
}
