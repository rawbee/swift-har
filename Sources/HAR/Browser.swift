public extension HAR {
    /// This object represents the web browser used.
    struct Browser: Equatable, Hashable, Codable, CustomStringConvertible,
        CustomDebugStringConvertible
    {
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

        /// Create browser.
        public init(name: String, version: String, comment: String? = nil) {
            self.name = name
            self.version = version
            self.comment = comment
        }

        // MARK: Describing Browsers

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
