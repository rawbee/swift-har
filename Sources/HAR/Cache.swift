public extension HAR {
    /// This objects contains info about a request coming from browser cache.
    struct Cache: Equatable, Hashable, Codable {
        // MARK: Properties

        /// State of a cache entry before the request. Leave out this field if the
        /// information is not available.
        public var beforeRequest: CacheEntry?

        /// State of a cache entry after the request. Leave out this field if the
        /// information is not available.
        public var afterRequest: CacheEntry?

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?

        // MARK: Initializers

        /// Create cache.
        public init() {}

        /// Create cache.
        public init(
            beforeRequest: CacheEntry? = nil,
            afterRequest: CacheEntry? = nil,
            comment: String? = nil
        ) {
            self.beforeRequest = beforeRequest
            self.afterRequest = afterRequest
            self.comment = comment
        }
    }
}
