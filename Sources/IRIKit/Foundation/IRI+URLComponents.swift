import Foundation

extension IRI {
    /// Creates an IRI from Foundation URL components.
    ///
    /// The components are mirrored with ``IRIComponents/init(_:)-(URLComponents)`` and
    /// assembled with ``IRI/init(components:)``, so the IRI is checked the same
    /// way as one built from ``IRIComponents``.
    ///
    /// - Parameter components: Foundation URL components that assemble into an absolute IRI.
    /// - Throws: `IRIError.invalidIRI` when the assembled value is not an
    ///   absolute IRI, or when it parses back into components that differ
    ///   from the mirrored components.
    public init(_ components: URLComponents) throws {
        try self.init(components: IRIComponents(components))
    }
}
