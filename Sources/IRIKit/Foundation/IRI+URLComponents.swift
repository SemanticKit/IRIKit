import Foundation

extension IRI {
    /// Creates an IRI from Foundation URL components.
    ///
    /// - Parameter components: Foundation URL components that assemble into an absolute IRI.
    /// - Throws: `IRIError.invalidIRI` when the assembled value is not an absolute IRI.
    public init(_ components: URLComponents) throws {
        try self.init(validating: components.string ?? "")
    }
}
