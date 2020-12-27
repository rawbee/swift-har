public extension HAR {
    /// This object describes timings for various events (states) fired during the page
    /// load. All times are specified in milliseconds. If a time info is not available
    /// appropriate field is set to -1.
    ///
    /// Depending on the browser, onContentLoad property represents `DOMContentLoad`
    /// event or `document.readyState == interactive`.
    struct PageTiming: Equatable, Hashable, Codable, CustomDebugStringConvertible {
        // MARK: Properties

        /// Content of the page loaded. Number of milliseconds since page load started
        /// (`page.startedDateTime`). Use -1 if the timing does not apply to the current
        /// request.
        public var onContentLoad: Double? = -1

        /// Page is loaded (onLoad event fired). Number of milliseconds since page load
        /// started (`page.startedDateTime`). Use -1 if the timing does not apply to the
        /// current request.
        public var onLoad: Double? = -1

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?

        // MARK: Initializers

        /// Create page timing.
        public init(onContentLoad: Double = -1, onLoad: Double = -1, comment: String? = nil) {
            self.onContentLoad = onContentLoad
            self.onLoad = onLoad
            self.comment = comment
        }

        // MARK: Describing Page Timings

        /// A human-readable debug description for the data.
        public var debugDescription: String {
            "HAR.PageTiming { onContentLoad: \(onContentLoad ?? -1), onLoad: \(onLoad ?? -1) }"
        }
    }
}
