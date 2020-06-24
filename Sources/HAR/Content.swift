import struct Foundation.Data

extension HAR {
    /// This object describes details about response content (embedded in `Response`
    /// object).
    public struct Content: Equatable, Hashable, Codable, CustomStringConvertible {
        // MARK: Properties

        /// Length of the returned content in bytes. Should be equal to
        /// `response.bodySize` if there is no compression and bigger when the content
        /// has been compressed.
        public var size: Int

        /// Number of bytes saved. Leave out this field if the information is not
        /// available.
        public var compression: Int?

        /// MIME type of the response text (value of the Content-Type response header).
        /// The charset attribute of the MIME type is included (if available).
        public var mimeType: String

        ///  Response body sent from the server or loaded from the browser cache. This
        /// field is populated with textual content only. The text field is either HTTP
        /// decoded text or a encoded (e.g. "base64") representation of the response
        /// body. Leave out this field if the information is not available.
        ///
        /// Before setting the text field, the HTTP response is decoded (decompressed &
        /// unchunked), than trans-coded from its original character set into UTF-8.
        /// Additionally, it can be encoded using e.g. base64. Ideally, the application
        /// should be able to unencode a base64 blob and get a byte-for-byte identical
        /// resource to what the browser operated on.
        public var text: String?

        /// Encoding used for response text field e.g "base64". Leave out this field if
        /// the text field is HTTP decoded (decompressed & unchunked), than trans-coded
        /// from its original character set into UTF-8.
        ///
        /// Encoding field is useful for including binary responses (e.g. images) into
        /// the HAR file.
        ///
        /// - Version: 1.2
        public var encoding: String?

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?

        // MARK: Computed Properties

        /// Get content body as Data. May return empty Data if text is encoded improperly.
        public var data: Data {
            guard let text = text else { return Data(count: 0) }
            switch encoding {
            case "base64":
                return Data(base64Encoded: text) ?? Data(count: 0)
            default:
                return Data(text.utf8)
            }
        }

        // MARK: Initializers

        /// Create content.
        public init(
            size: Int, compression: Int? = nil, mimeType: String, text: String? = nil,
            encoding: String? = nil, comment: String? = nil
        ) {
            self.size = size
            self.compression = compression
            self.mimeType = mimeType
            self.text = text
            self.encoding = encoding
            self.comment = comment
        }

        /// Create empty unknown response body content.
        public init() {
            self.size = 0
            self.mimeType = "application/octet-stream"
        }

        /// Create HAR Content from string.
        public init(text: String, encoding: String? = nil, mimeType: String?) {
            self.init()

            if let mimeType = mimeType {
                self.mimeType = mimeType
            }

            self.encoding = encoding
            self.text = text
            self.size = data.count
        }

        /// Create HAR Content decoding HTTP Body Data.
        public init(decoding data: Data, mimeType: String?) {
            self.init()

            if let mimeType = mimeType {
                self.mimeType = mimeType
            }

            self.size = data.count

            if let text = String(bytes: data, encoding: .utf8) {
                self.text = text
            } else {
                self.text = data.base64EncodedString()
                self.encoding = "base64"
            }
        }

        /// Create HAR Content from text string.
        public init(_ description: String) {
            self.init(text: description, mimeType: "text/plain")
        }

        /// A human-readable description for the data.
        public var description: String {
            String(decoding: data, as: UTF8.self)
        }
    }
}
