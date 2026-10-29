/// The scheme-specific facts RFC 3987 section 5.3.3 normalization relies on.
struct IRISchemeNormalizationRule: Sendable {
    /// The port that is equivalent to an elided port.
    let defaultPort: Int

    /// Returns the rule for a scheme whose specification requires a host,
    /// defines a default port, and makes an empty path equivalent to `/`:
    ///
    /// - `http` and `https`: RFC 9110 section 4.2.1 and 4.2.2 (default ports
    ///   80 and 443, a host is required) and section 4.2.3 (an omitted
    ///   default port and an empty path equal to `/` are the normal form).
    /// - `ws` and `wss`: RFC 6455 section 3 (default ports 80 and 443, a
    ///   host is required, and the resource name is `/` when the path is
    ///   empty).
    /// - `ftp`: RFC 1738 section 3.2 (default port 21), section 3.1 (the `/`
    ///   after the host is not part of the url-path, so an empty path and `/`
    ///   name the same url-path) and section 5 (`ftpurl` requires a host).
    init?(scheme: String) {
        switch scheme.lowercased() {
        case "http", "ws":
            defaultPort = 80
        case "https", "wss":
            defaultPort = 443
        case "ftp":
            defaultPort = 21
        default:
            return nil
        }
    }
}
