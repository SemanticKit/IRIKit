/// The scheme-specific facts RFC 3987 section 5.3.3 normalization relies on.
struct IRISchemeNormalizationRule: Sendable {
    /// The port that is equivalent to an elided port.
    let defaultPort: Int

    /// Returns the rule for a scheme whose specification defines an
    /// authority with a DNS host, a default port, and an empty path that is
    /// equivalent to `/`.
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
