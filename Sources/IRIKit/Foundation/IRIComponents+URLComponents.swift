import Foundation

extension IRIComponents {
    /// Creates IRI components from Foundation URL components.
    ///
    /// The authority is assembled as RFC 3986 section 3.2 defines it,
    /// `[ userinfo "@" ] host [ ":" port ]`, from the percent-encoded user,
    /// password and host and the port. A port delimiter with no digits is kept
    /// as an empty port. The authority is `nil` only when the components have
    /// no user, password, host or port.
    ///
    /// The host is taken from `percentEncodedHost`, so a host set through
    /// `URLComponents.host` comes out percent-encoded, such as
    /// `r%C3%A4k.example`, not in Foundation's IDNA form.
    ///
    /// - Parameter components: The Foundation URL components to mirror.
    public init(_ components: URLComponents) {
        self.init(
            scheme: components.scheme ?? "",
            authority: Self.authority(of: components),
            path: components.percentEncodedPath,
            query: components.percentEncodedQuery,
            fragment: components.percentEncodedFragment
        )
    }

    private static func authority(of components: URLComponents) -> String? {
        let user = components.percentEncodedUser
        let password = components.percentEncodedPassword
        let host = components.percentEncodedHost
        let port = portText(of: components)
        guard user != nil || password != nil || host != nil || port != nil else {
            return nil
        }

        var authority = ""
        // userinfo = *( unreserved / pct-encoded / sub-delims / ":" )
        if user != nil || password != nil {
            authority += user ?? ""
            if let password {
                authority += ":\(password)"
            }
            authority += "@"
        }
        authority += host ?? ""
        if let port {
            authority += ":\(port)"
        }
        return authority
    }

    /// Returns the port text as the components hold it, `""` for a port
    /// delimiter with no digits, or `nil` when there is no port.
    ///
    /// RFC 3986 section 3.2.3 defines `port = *DIGIT`, so the text is kept
    /// verbatim: `components.port` is an `Int`, which drops a port too large
    /// for `Int` and rewrites `007` as `7`.
    private static func portText(of components: URLComponents) -> String? {
        if let string = components.string {
            if let range = components.rangeOfPort {
                return String(string[range])
            }
            // Whether `rangeOfPort` is nil or empty for an empty port depends
            // on the host form: with Swift 6.4 on Linux it is nil for
            // "http://example.com:/a" but empty for "http://[::1]:/a". When
            // it is nil, look for ":" right after the host.
            if let host = components.rangeOfHost,
                host.upperBound < string.endIndex,
                string[host.upperBound] == ":"
            {
                return ""
            }
        }
        // `string` is nil when the components cannot be assembled, such as
        // an unbracketed IPv6 host; only the numeric port is left then.
        return components.port.map(String.init)
    }
}
