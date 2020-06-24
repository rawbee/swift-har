import struct Foundation.Data
import struct Foundation.URLComponents

extension HAR {
    /// This object describes posted data, if any (embedded in `Request` object).
    public struct PostData: Equatable, Hashable, Codable, CustomStringConvertible {
        // MARK: Properties

        /// Mime type of posted data.
        public var mimeType: String

        /// List of posted parameters (in case of URL encoded parameters).
        ///
        /// - Invariant: Text and params fields are mutually exclusive.
        public var params: Params

        /// Plain text posted data
        ///
        /// - Invariant: Text and params fields are mutually exclusive.
        public var text: String

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?

        // MARK: Computed Properties

        /// Get text as UTF8 Data.
        public var data: Data {
            Data(text.utf8)
        }

        /// Get bytesize of text.
        public var size: Int {
            data.count
        }

        // MARK: Initializers

        /// Create post data.
        public init(mimeType: String, params: Params, text: String, comment: String? = nil) {
            self.mimeType = mimeType
            self.params = params
            self.text = text
            self.comment = comment
        }

        /// Create HAR PostData from plain text.
        public init(parsingText text: String, mimeType: String?) {
            self.text = text

            self.mimeType = "application/octet-stream"
            if let mimeType = mimeType {
                self.mimeType = mimeType
            }

            self.params = []
            if self.mimeType.hasPrefix("application/x-www-form-urlencoded") {
                self.params = parseFormUrlEncoded(self.text)
            }
        }

        private func parseFormUrlEncoded(_ str: String) -> Params {
            var components = URLComponents()
            components.query = str
            return components.queryItems?.map {
                return Param(
                    name: $0.name,
                    value:
                    $0.value?
                        .replacingOccurrences(of: "+", with: "%20")
                        .removingPercentEncoding ?? ""
                )
            } ?? []
        }

        /// Create HAR PostData from data.
        public init?(parsingData data: Data, mimeType: String?) {
            guard let text = String(bytes: data, encoding: .utf8) else {
                return nil
            }
            self.init(parsingText: text, mimeType: mimeType)
        }

        // MARK: Encoding and Decoding

        /// Create PostData from Decoder.
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            mimeType = try container.decodeIfPresent(String.self, forKey: .mimeType) ?? ""
            self.params = try container.decodeIfPresent(Params.self, forKey: .params) ?? []
            self.text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
            self.comment = try container.decodeIfPresent(String.self, forKey: .comment)
        }

        /// A human-readable description for the data.
        public var description: String {
            text
        }
    }
}
