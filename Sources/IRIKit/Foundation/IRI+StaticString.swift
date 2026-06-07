extension IRI {
    /// Creates an IRI from a static string.
    ///
    /// - Parameter value: A static string containing an absolute IRI.
    /// - Throws: `IRIError.invalidIRI` when the value is not an absolute IRI.
    public init(_ value: StaticString) throws {
        try self.init(validating: value.description)
    }
}
