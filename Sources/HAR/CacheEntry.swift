import Foundation

extension HAR {
    /// This objects contains cache entry state for the request.
    public struct CacheEntry: Equatable, Hashable, Codable {
        // MARK: Properties

        /// Expiration time of the cache entry.
        public var expires: Date?

        /// The last time the cache entry was opened.
        public var lastAccess: Date

        /// Etag
        public var eTag: String

        /// The number of times the cache entry has been opened.
        public var hitCount: Int

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?

        // MARK: Initializers

        /// Create cache entry.
        public init(
            expires: Date? = nil, lastAccess: Date, eTag: String, hitCount: Int, comment: String? = nil
        ) {
            self.expires = expires
            self.lastAccess = lastAccess
            self.eTag = eTag
            self.hitCount = hitCount
            self.comment = comment
        }
    }
}
