import Foundation

extension IRIComponents {
    /// Creates IRI components from Foundation URL components.
    ///
    /// The authority is assembled as RFC 3986 section 3.2 defines it,
    /// `[ userinfo "@" ] host [ ":" port ]`, from the percent-encoded user,
    /// password and host and the port. The authority is `nil` only when the
    /// components have no user, password, host or port.
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
        }
        return authority
    }
}
