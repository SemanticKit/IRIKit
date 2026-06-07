/// A component-based representation for constructing an absolute IRI.
///
/// `IRIComponents` lets callers assemble an IRI from its generic syntax
/// components instead of concatenating raw strings.
public struct IRIComponents {
    /// The IRI scheme.
    public var scheme: String

    /// The authority component, when the IRI uses `//`.
    public var authority: String?

    /// The path component.
    public var path: String

    /// The query component without the leading question mark.
    public var query: String?

    /// The fragment component without the leading number sign.
    public var fragment: String?

    /// Creates component values for an absolute IRI.
    ///
    /// - Parameters:
    ///   - scheme: The IRI scheme.
    ///   - authority: The authority component, when the IRI uses `//`.
    ///   - path: The path component.
    ///   - query: The query component without the leading question mark.
    ///   - fragment: The fragment component without the leading number sign.
    public init(
        scheme: String,
        authority: String? = nil,
        path: String = "",
        query: String? = nil,
        fragment: String? = nil
    ) {
        self.scheme = scheme
        self.authority = authority
        self.path = path
        self.query = query
        self.fragment = fragment
    }

    /// Creates a validated absolute IRI from these components.
    ///
    /// - Throws: `IRIError.invalidIRI` when the assembled character sequence
    ///   is not an absolute IRI.
    public func iri() throws -> IRI {
        try IRI(validating: string)
    }

    /// The assembled IRI character sequence.
    public var string: String {
        var result = "\(scheme):"
        if let authority {
            result += "//\(authority)"
        }
        result += path
        if let query {
            result += "?\(query)"
        }
        if let fragment {
            result += "#\(fragment)"
        }
        return result
    }
}

extension IRIComponents: Codable {}

extension IRIComponents: Equatable {}

extension IRIComponents: Hashable {}

extension IRIComponents: Sendable {}
