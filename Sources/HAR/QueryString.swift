import Foundation

extension HAR {
    /// This object contains list of all parameters & values parsed from a query string,
    /// if any (embedded in `Request` object).
    public struct QueryString: Equatable, Hashable, Codable, CustomStringConvertible,
        CustomDebugStringConvertible {
        // MARK: Properties

        /// The query parameter name.
        public var name: String

        /// The query parameter value.
        public var value: String

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?

        // MARK: Initializers

        /// Create query string.
        public init(name: String, value: String, comment: String? = nil) {
            self.name = name
            self.value = value
            self.comment = comment
        }

        /// Create QueryString item from `URLQueryItem`.
        internal init(_ queryItem: URLQueryItem) {
            self.name = queryItem.name
            self.value = queryItem.value?.replacingOccurrences(of: "+", with: " ") ?? ""
        }

        // MARK: Describing Query Strings

        /// A human-readable description for the data.
        public var description: String {
            "\(name)=\(value)"
        }

        /// A human-readable debug description for the data.
        public var debugDescription: String {
            "HAR.QueryString { \(description) }"
        }
    }

    /// Array of QueryString objects.
    public typealias QueryStrings = [QueryString]
}
