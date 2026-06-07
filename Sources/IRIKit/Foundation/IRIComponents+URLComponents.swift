import Foundation

extension IRIComponents {
    /// Creates IRI components from Foundation URL components.
    ///
    /// - Parameter components: The Foundation URL components to mirror.
    public init(_ components: URLComponents) {
        self.init(
            scheme: components.scheme ?? "",
            authority: components.percentEncodedHost,
            path: components.percentEncodedPath,
            query: components.percentEncodedQuery,
            fragment: components.percentEncodedFragment
        )
    }
}

