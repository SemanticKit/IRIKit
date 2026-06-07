extension IRI {
    /// Creates an IRI from a substring.
    ///
    /// - Parameter value: A substring containing an absolute IRI.
    /// - Throws: `IRIError.invalidIRI` when the value is not an absolute IRI.
    public init(_ value: Substring) throws {
        try self.init(validating: String(value))
    }
}
