/// The components of an IRI after RFC 3987 section 5.3 normalization.
///
/// RFC 3986 section 6.2.2 applies normalization to the components, and
/// RFC 3986 section 5.2.4 `remove_dot_segments` can return a path that
/// begins with `//` when there is no authority (for example `//a` from
/// `/.//a`). RFC 3986 section 3.3 rules such a path out of IRI text, because
/// the text would read as an authority, so that normal form has no text.
/// Comparison therefore uses these components: two IRIs are equivalent when
/// their normalized components are equal. Where the components can be
/// written as text, that is the same as comparing the recomposed text.
struct NormalizedIRIComponents: Equatable, Sendable {
    var scheme: String
    var authority: String?
    var path: String
    var query: String?
    var fragment: String?

    /// Compares the components as Unicode scalar sequences.
    ///
    /// Swift `String` equality treats canonically equivalent text as equal,
    /// which would apply character normalization (RFC 3987 section 5.3.2.2)
    /// even when it was not requested. RFC 3987 section 5.3.1 compares
    /// character by character, so the scalars are compared.
    static func == (lhs: Self, rhs: Self) -> Bool {
        sameUnicodeScalars(lhs.scheme, rhs.scheme)
            && sameUnicodeScalars(lhs.authority, rhs.authority)
            && sameUnicodeScalars(lhs.path, rhs.path)
            && sameUnicodeScalars(lhs.query, rhs.query)
            && sameUnicodeScalars(lhs.fragment, rhs.fragment)
    }

    /// The IRI text recomposed as in RFC 3986 section 5.3, or `nil` when
    /// RFC 3986 section 3.3 forbids the path: there is no authority and the
    /// path begins with `//`.
    var recomposed: String? {
        if authority == nil, path.unicodeScalars.starts(with: "//".unicodeScalars) {
            return nil
        }
        var result = scheme + ":"
        if let authority {
            result += "//" + authority
        }
        result += path
        if let query {
            result += "?" + query
        }
        if let fragment {
            result += "#" + fragment
        }
        return result
    }
}
