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
        let port = components.port
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
        } else if hasEmptyPort(components) {
            // RFC 3986 section 3.2.3: port = *DIGIT, so "host:" is a valid
            // authority with an empty port, and `port` is nil for it.
            authority += ":"
        }
        return authority
    }

    /// Returns whether the components hold a port delimiter with no digits.
    private static func hasEmptyPort(_ components: URLComponents) -> Bool {
        if let range = components.rangeOfPort {
            return range.isEmpty
        }
        // Some Foundation versions report no port range for an empty port,
        // so look for ":" right after the host.
        guard
            let string = components.string,
            let host = components.rangeOfHost,
            host.upperBound < string.endIndex
        else {
            return false
        }
        return string[host.upperBound] == ":"
    }
}
