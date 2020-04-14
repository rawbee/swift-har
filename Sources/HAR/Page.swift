import Foundation

extension HAR {
    /// This object represents list of exported pages.
    public struct Page: Equatable, Hashable, Codable, CustomStringConvertible,
        CustomDebugStringConvertible {
        // MARK: Properties

        /// Date and time stamp for the beginning of the page load.
        public var startedDateTime: Date

        /// Unique identifier of a page within the `Log`. Entries use it to refer the
        /// parent page.
        public var id: String

        /// Page title.
        public var title: String

        /// Detailed timing info about page load.
        public var pageTimings: PageTiming

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?

        // MARK: Initializers

        /// Create page.
        public init(
            startedDateTime: Date, id: String, title: String = "", pageTimings: PageTiming = .init(),
            comment: String? = nil
        ) {
            self.startedDateTime = startedDateTime
            self.id = id
            self.title = title
            self.pageTimings = pageTimings
            self.comment = comment
        }

        // MARK: Encoding and Decoding

        /// Create Page from Decoder.
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            startedDateTime = try container.decode(Date.self, forKey: .startedDateTime)
            id = try container.decode(String.self, forKey: .id)
            title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
            self.pageTimings = try container.decode(PageTiming.self, forKey: .pageTimings)
            self.comment = try container.decodeIfPresent(String.self, forKey: .comment)
        }

        // MARK: Describing Pages

        /// Date formatter for Page description.
        private static let startedDateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d/yyyy, h:mm:ss a"
            return formatter
        }()

        /// A human-readable description for the data.
        public var description: String {
            var strs: [String] = []

            if let onLoad = pageTimings.onLoad {
                strs.append("\(onLoad.rounded())ms")
            }

            strs.append(Self.startedDateFormatter.string(from: startedDateTime))
            strs.append(title)

            return strs.joined(separator: "  ")
        }

        /// A human-readable debug description for the data.
        public var debugDescription: String {
            "HAR.Page { \(description) }"
        }
    }

    /// Array of Page objects.
    public typealias Pages = [Page]
}
