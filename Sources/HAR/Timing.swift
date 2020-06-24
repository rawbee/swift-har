extension HAR {
    /// This object describes various phases within request-response round trip. All
    /// times are specified in milliseconds.
    public struct Timing: Equatable, Hashable, Codable, CustomDebugStringConvertible {
        // MARK: Properties

        /// Time spent in a queue waiting for a network connection. Use -1 if the timing
        /// does not apply to the current request.
        public var blocked: Double? = -1

        /// DNS resolution time. The time required to resolve a host name. Use -1 if the
        /// timing does not apply to the current request.
        public var dns: Double? = -1

        ///  Time required to create TCP connection. Use -1 if the timing does not apply
        /// to the current request.
        public var connect: Double? = -1

        /// Time required to send HTTP request to the server.
        public var send: Double

        /// Waiting for a response from the server.
        public var wait: Double

        /// Time required to read entire response from the server (or cache).
        public var receive: Double

        /// Time required for SSL/TLS negotiation. If this field is defined then the
        /// time is also included in the connect field (to ensure backward compatibility
        /// with HAR 1.1). Use -1 if the timing does not apply to the current request.
        ///
        /// - Version: 1.2
        public var ssl: Double? = -1

        /// A comment provided by the user or the application.
        ///
        /// - Version: 1.2
        public var comment: String?

        // MARK: Computed Properties

        /// Compute total request time.
        ///
        /// The time value for the request must be equal to the sum of the timings supplied
        /// in this section (excluding any -1 values).
        public var total: Double {
            [blocked, dns, connect, send, wait, receive]
                .map { $0 ?? -1 }
                .filter { $0 != -1 }
                .reduce(0, +)
        }

        // MARK: Initializers

        /// Create timing.
        public init(
            blocked: Double? = -1,
            dns: Double? = -1,
            connect: Double? = -1,
            send: Double = -1,
            wait: Double = -1,
            receive: Double = -1,
            ssl: Double? = -1,
            comment: String? = nil
        ) {
            self.blocked = blocked
            self.dns = dns
            self.connect = connect
            self.send = send
            self.wait = wait
            self.receive = receive
            self.ssl = ssl
            self.comment = comment
        }

        // MARK: Describing Timings

        /// A human-readable debug description for the data.
        public var debugDescription: String {
            """
            HAR.Timing {
                Blocked: \(blocked ?? -1)ms
                DNS: \(dns ?? -1)ms
                SSL/TLS: \(ssl ?? -1)ms
                Connect: \(connect ?? -1)ms
                Send: \(send)ms
                Wait: \(wait)ms
                Receive: \(receive)ms
            }
            """
        }
    }
}
