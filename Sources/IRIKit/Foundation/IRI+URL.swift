import Foundation

extension IRI {
    /// Creates an IRI from a Foundation URL.
    ///
    /// - Parameter url: A Foundation URL containing an absolute URI string.
    /// - Throws: `IRIError.invalidIRI` when the URL string is not an absolute
    ///   IRI.
    public init(_ url: URL) throws {
        try self.init(validating: IRIURIMapping.iriString(fromURIString: url.absoluteString))
    }
}
