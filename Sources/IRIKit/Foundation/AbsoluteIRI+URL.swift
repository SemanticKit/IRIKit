import Foundation

extension AbsoluteIRI {
    /// Creates an absolute IRI from a Foundation URL.
    ///
    /// - Parameter url: A Foundation URL containing an absolute URI string
    ///   without a fragment.
    /// - Throws: `IRIError.invalidIRI` when the URL string is not an absolute
    ///   IRI or contains a fragment.
    public init(_ url: URL) throws {
        try self.init(validating: IRIURIMapping.iriString(fromURIString: url.absoluteString))
    }
}
