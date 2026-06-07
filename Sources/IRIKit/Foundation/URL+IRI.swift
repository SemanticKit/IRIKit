import Foundation

extension URL {
    /// Creates a Foundation URL from an IRI.
    ///
    /// The IRI character sequence is mapped to URI form before constructing the
    /// URL.
    public init(_ iri: IRI) {
        self = URL(string: IRIURIMapping.uriString(from: iri.rawValue))!
    }

    /// Creates a Foundation URL from an IRI reference.
    ///
    /// The IRI reference character sequence is mapped to URI-reference form
    /// before constructing the URL.
    public init(_ reference: IRIReference) {
        self = URL(string: IRIURIMapping.uriString(from: reference.rawValue))!
    }

    /// Creates a Foundation URL from an absolute IRI.
    ///
    /// The absolute IRI character sequence is mapped to URI form before
    /// constructing the URL.
    public init(_ iri: AbsoluteIRI) {
        self = URL(string: IRIURIMapping.uriString(from: iri.rawValue))!
    }
}
