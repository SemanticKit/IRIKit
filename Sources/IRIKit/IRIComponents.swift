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

    /// Creates component values for an absolute IRI with structured query items.
    ///
    /// Query items are joined with `&` and stored as the query component without
    /// applying percent-encoding. An empty query item list omits the query
    /// component. Use the raw `query:` initializer when an explicit empty query
    /// is required.
    ///
    /// Because values are not percent-encoded, a "#" in a name or value ends
    /// the query when the IRI is parsed. Write it as `%23`. ``IRI/init(components:)``
    /// rejects components that do not read back unchanged.
    ///
    /// - Parameters:
    ///   - scheme: The IRI scheme.
    ///   - authority: The authority component, when the IRI uses `//`.
    ///   - path: The path component.
    ///   - queryItems: The query items to join with `&`.
    ///   - fragment: The fragment component without the leading number sign.
    public init(
        scheme: String,
        authority: String? = nil,
        path: String = "",
        queryItems: [IRIQueryItem],
        fragment: String? = nil
    ) {
        self.init(
            scheme: scheme,
            authority: authority,
            path: path,
            query: queryItems.isEmpty
                ? nil
                : queryItems.map(\.string).joined(separator: "&"),
            fragment: fragment
        )
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

extension IRIComponents: Equatable {
    /// Returns whether each component holds the same Unicode scalar sequence,
    /// matching IRI equality, so canonically equivalent but different scalar
    /// sequences are not equal.
    public static func == (lhs: IRIComponents, rhs: IRIComponents) -> Bool {
        sameScalars(lhs.scheme, rhs.scheme)
            && sameScalars(lhs.authority, rhs.authority)
            && sameScalars(lhs.path, rhs.path)
            && sameScalars(lhs.query, rhs.query)
            && sameScalars(lhs.fragment, rhs.fragment)
    }

    private static func sameScalars(_ lhs: String?, _ rhs: String?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case let (lhs?, rhs?):
            return lhs.unicodeScalars.elementsEqual(rhs.unicodeScalars)
        default:
            return false
        }
    }
}

extension IRIComponents: Hashable {
    /// Hashes the Unicode scalar sequence of each component.
    public func hash(into hasher: inout Hasher) {
        Self.combine(scheme, into: &hasher)
        Self.combine(authority, into: &hasher)
        Self.combine(path, into: &hasher)
        Self.combine(query, into: &hasher)
        Self.combine(fragment, into: &hasher)
    }

    private static func combine(_ component: String?, into hasher: inout Hasher) {
        guard let component else {
            hasher.combine(false)
            return
        }
        hasher.combine(true)
        // A count before the scalars keeps adjacent components apart.
        hasher.combine(component.unicodeScalars.count)
        for scalar in component.unicodeScalars {
            hasher.combine(scalar.value)
        }
    }
}

extension IRIComponents: Sendable {}
