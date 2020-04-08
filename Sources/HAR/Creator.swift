extension HAR {
    /// This object represents the log creator application.
    public struct Creator: Equatable, Hashable, Codable, CustomStringConvertible,
        CustomDebugStringConvertible {
        // MARK: Static Properties

        /// Creator info used when this library creates a new HAR log.
        public static let `default` = Self(name: "SwiftHAR", version: "0.1.0")

        // MARK: Properties

        /// Name of the application/browser used to export the log.
        public var name: String

        /// Version of the application/browser used to export the log.
        public var version: String

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?

        // MARK: Initializers

        /// Create creator.
        public init(name: String, version: String, comment: String? = nil) {
            self.name = name
            self.version = version
            self.comment = comment
        }

        // MARK: Describing Creators

        /// A human-readable description for the data.
        public var description: String {
            "\(name)/\(version)"
        }

        /// A human-readable debug description for the data.
        public var debugDescription: String {
            "HAR.Browser { \(description) }"
        }
    }
}
