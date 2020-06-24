extension HAR {
    /// This object represents the root of exported data.
    ///
    /// There is one `Page` object for every exported web page and one `Entry` object
    /// for every HTTP request. In case when an HTTP trace tool isn't able to group
    /// requests by a page, the `pages` object is empty and individual requests doesn't
    /// have a parent page.
    public struct Log: Equatable, Hashable, Codable {
        // MARK: Properties

        /// Version number of the format. If empty, string "1.1" is assumed by default.
        public var version: String

        /// Name and version info of the log creator application.
        public var creator: Creator

        /// Name and version info of used browser.
        public var browser: Browser?

        /// List of all exported (tracked) pages. Leave out this field if the
        /// application does not support grouping by pages.
        public var pages: Pages?

        /// List of all exported (tracked) requests.
        public var entries: Entries

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?

        // MARK: Computed Properties

        /// Access log's first entry.
        ///
        /// - Invariant: Log's must have at least one entry to be valid.
        /// However, a log maybe empty on initial construction.
        public var firstEntry: Entry {
            guard let entry = entries.first else {
                preconditionFailure("HAR.Log has no entries")
            }
            return entry
        }

        // MARK: Initializers

        /// Create log.
        public init(
            version: String = "1.2",
            creator: Creator = .default,
            browser: Browser? = nil,
            pages: Pages? = nil,
            entries: Entries = [],
            comment: String? = nil
        ) {
            self.version = version
            self.creator = creator
            self.browser = browser
            self.pages = pages
            self.entries = entries
            self.comment = comment
        }
    }
}
