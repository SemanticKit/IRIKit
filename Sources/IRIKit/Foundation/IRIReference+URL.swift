import Foundation

extension IRIReference {
    /// Creates an IRI reference from a Foundation URL.
    ///
    /// - Parameter url: A Foundation URL containing a URI reference string.
    /// - Throws: `IRIError.invalidIRIReference` when the URL string is not an
    ///   IRI reference.
    public init(_ url: URL) throws {
        try self.init(validating: IRIURIMapping.iriString(fromURIString: url.relativeString))
    }
}
