@testable import IRIKit

/// The reference resolution algorithm of RFC 3986 section 5.2, which
/// RFC 3987 section 6.5 applies to IRI references.
///
/// IRIKit does not resolve references; callers such as RDF decoders do. This
/// test helper follows the pseudocode of section 5.2.2 so that the tests can
/// check what such a caller needs from IRIKit: the base parses into its
/// components, including an empty authority, each reference validates, and
/// each target assembles through ``IRI/init(components:)`` and reads back
/// unchanged.
enum ReferenceResolver {
    /// The five components of a reference, split by the regular expression
    /// of RFC 3986 appendix B. A component that is absent is `nil`.
    ///
    /// Delimiters are found by Unicode scalar, as IRIKit's parser finds
    /// them, not by `Character`: a delimiter followed by a combining mark,
    /// such as "#" and U+0301, is one `Character` that is not "#".
    struct Parts {
        var scheme: String?
        var authority: String?
        var path: String
        var query: String?
        var fragment: String?
    }

    static func parts(of reference: String) -> Parts {
        var rest = reference.unicodeScalars[...]
        var parts = Parts(path: "")
        // ^(([^:/?#]+):)?
        if let colon = rest.firstIndex(where: { ":/?#".unicodeScalars.contains($0) }),
            rest[colon] == ":", colon != rest.startIndex
        {
            parts.scheme = text(rest[..<colon])
            rest = rest[rest.index(after: colon)...]
        }
        // (//([^/?#]*))?
        if rest.starts(with: "//".unicodeScalars) {
            rest = rest.dropFirst(2)
            let end = rest.firstIndex(where: { "/?#".unicodeScalars.contains($0) }) ?? rest.endIndex
            parts.authority = text(rest[..<end])
            rest = rest[end...]
        }
        // (#(.*))?
        if let hash = rest.firstIndex(of: "#") {
            parts.fragment = text(rest[rest.index(after: hash)...])
            rest = rest[..<hash]
        }
        // (\?([^#]*))?
        if let question = rest.firstIndex(of: "?") {
            parts.query = text(rest[rest.index(after: question)...])
            rest = rest[..<question]
        }
        parts.path = text(rest)
        return parts
    }

    private static func text(_ scalars: Substring.UnicodeScalarView) -> String {
        String(Substring(scalars))
    }

    /// Resolves `reference` against `base` with the strict parser of
    /// section 5.2.2 and returns the target IRI.
    static func resolve(_ reference: IRIReference, against base: IRI) throws -> IRI {
        let r = parts(of: reference.rawValue)
        let target: IRIComponents
        if let scheme = r.scheme {
            target = IRIComponents(
                scheme: scheme,
                authority: r.authority,
                path: removeDotSegments(r.path),
                query: r.query,
                fragment: r.fragment
            )
        } else if r.authority != nil {
            target = IRIComponents(
                scheme: base.scheme,
                authority: r.authority,
                path: removeDotSegments(r.path),
                query: r.query,
                fragment: r.fragment
            )
        } else if r.path.isEmpty {
            target = IRIComponents(
                scheme: base.scheme,
                authority: base.authority,
                path: base.path,
                query: r.query ?? base.query,
                fragment: r.fragment
            )
        } else if r.path.hasPrefix("/") {
            target = IRIComponents(
                scheme: base.scheme,
                authority: base.authority,
                path: removeDotSegments(r.path),
                query: r.query,
                fragment: r.fragment
            )
        } else {
            target = IRIComponents(
                scheme: base.scheme,
                authority: base.authority,
                path: removeDotSegments(merge(base: base, path: r.path)),
                query: r.query,
                fragment: r.fragment
            )
        }
        return try IRI(components: target)
    }

    /// RFC 3986 section 5.2.3.
    static func merge(base: IRI, path: String) -> String {
        if base.authority != nil, base.path.isEmpty {
            return "/" + path
        }
        guard let slash = base.path.lastIndex(of: "/") else {
            return path
        }
        return String(base.path[...slash]) + path
    }

    /// RFC 3986 section 5.2.4, as IRIKit implements it for normalization.
    static func removeDotSegments(_ path: String) -> String {
        IRINormalizer.removingDotSegments(from: path)
    }
}
