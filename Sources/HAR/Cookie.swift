import struct Foundation.Date
import class Foundation.DateFormatter
import struct Foundation.TimeZone

extension HAR {
    /// This object contains list of all cookies (used in `Request` and `Response`
    /// objects).
    public struct Cookie: Equatable, Hashable, Codable {
        // MARK: Properties

        /// The name of the cookie.
        public var name: String

        /// The cookie value.
        public var value: String

        /// The path pertaining to the cookie.
        public var path: String?

        // The host of the cookie.
        public var domain: String?

        /// Cookie expiration time.
        public var expires: Date?

        /// Set to true if the cookie is HTTP only, false otherwise.
        public var httpOnly: Bool?

        /// True if the cookie was transmitted over ssl, false otherwise.
        ///
        /// - Version: 1.2
        public var secure: Bool?

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?

        /// The SameSite cross-origin policy of the cookie.
        ///
        /// Possible values: `"strict"`, `"lax"`, `"none"`
        ///
        /// - Version: Unspecified
        public var sameSite: String?

        // MARK: Initializers

        /// Create cookie.
        public init(
            name: String,
            value: String,
            path: String? = nil,
            domain: String? = nil,
            expires: Date? = nil,
            httpOnly: Bool? = nil,
            secure: Bool? = nil,
            comment: String? = nil,
            sameSite: String? = nil
        ) {
            self.name = name
            self.value = value
            self.path = path
            self.domain = domain
            self.expires = expires
            self.httpOnly = httpOnly
            self.secure = secure
            self.comment = comment
            self.sameSite = sameSite
        }

        /// Create Cookie from HTTP Response "Set-Cookie" header value.
        internal init(fromSetCookieHeader header: String) {
            var attributeValues = Self.parseCookieAttributes(header)

            let (name, value) = attributeValues.removeFirst()
            self.name = name
            self.value = value ?? ""

            self.secure = false
            self.httpOnly = false

            for (key, value) in attributeValues {
                switch key.lowercased() {
                case "expires":
                    if let value = value {
                        self.expires = parseExpires(value)
                    }
                case "domain":
                    self.domain = value
                case "path":
                    self.path = value
                case "secure":
                    self.secure = true
                case "httponly":
                    self.httpOnly = true
                case "samesite":
                    self.sameSite = value
                default:
                    continue
                }
            }
        }

        /// Date Formatter to attempt parsing "Expires" strings.
        /// "Tue, 18 Jan 2022 23:07:07 GMT"
        private static let expiresDateFormats = [
            "EEE',' dd MMM yyyy HH:mm:ss 'GMT'",
            "EEE',' dd'-'MMM'-'yy HH:mm:ss 'GMT'",
            "EEE',' dd'-'MMM'-'yyyy HH:mm:ss 'GMT'",
        ]

        /// Parse Set-Cookie expires strings.
        private func parseExpires(_ string: String) -> Date? {
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone(identifier: "UTC")

            for dateFormat in Self.expiresDateFormats {
                formatter.dateFormat = dateFormat
                if let date = formatter.date(from: string) {
                    return date
                }
            }

            return nil
        }

        // MARK: Static Methods

        /// Parse cookie style attribute pairs seperated by `;` and `=`
        internal static func parseCookieAttributes(_ string: String) -> [(key: String, value: String?)] {
            string.split(separator: ";").compactMap {
                let parts = $0.split(separator: "=", maxSplits: 1)
                let key = String(parts[0])
                let value = parts.count > 1 ? String(parts[1]) : nil
                return (
                    key.trimmingCharacters(in: .whitespaces),
                    value?.trimmingCharacters(in: .whitespaces)
                )
            }
        }
    }

    /// Array of Cookie objects.
    public typealias Cookies = [Cookie]
}

extension HAR.Cookies {
    // MARK: Initializers

    /// Create Cookies array from HTTP Request "Cookie:" header value.
    public init(fromCookieHeader header: String) {
        self = HAR.Cookie.parseCookieAttributes(header).map {
            HAR.Cookie(name: $0.key, value: $0.value ?? "")
        }
    }
}
