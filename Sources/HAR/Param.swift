extension HAR {
    /// List of posted parameters, if any (embedded in `PostData` object).
    public struct Param: Equatable, Hashable, Codable, CustomStringConvertible,
        CustomDebugStringConvertible {
        // MARK: Properties

        /// Name of a posted parameter.
        public var name: String

        /// Value of a posted parameter or content of a posted file.
        public var value: String?

        /// Name of a posted file.
        public var fileName: String?

        /// Content type of a posted file.
        public var contentType: String?

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?

        // MARK: Initializers

        /// Create param.
        public init(
            name: String, value: String? = nil, fileName: String? = nil, contentType: String? = nil,
            comment: String? = nil
        ) {
            self.name = name
            self.value = value
            self.fileName = fileName
            self.contentType = contentType
            self.comment = comment
        }

        // MARK: Encoding and Decoding

        /// Create Param from Decoder.
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            /// Override synthesised decoder to handle empty `name`.
            name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""

            self.value = try container.decodeIfPresent(String.self, forKey: .value)
            self.fileName = try container.decodeIfPresent(String.self, forKey: .fileName)
            self.contentType = try container.decodeIfPresent(String.self, forKey: .contentType)
        }

        // MARK: Describing Params

        /// A human-readable description for the data.
        public var description: String {
            var str = "\(name)"

            if let fileName = fileName {
                str += "=@\(fileName)"

                if let contentType = contentType {
                    str += ";type=\(contentType)"
                }
            } else if let value = value {
                str += "=\(value)"
            }

            return str
        }

        /// A human-readable debug description for the data.
        public var debugDescription: String {
            "HAR.Param { \(description) }"
        }
    }

    /// Array of Param objects.
    public typealias Params = [Param]
}
