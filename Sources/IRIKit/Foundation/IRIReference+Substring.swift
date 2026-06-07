extension IRIReference {
    /// Creates an IRI reference from a substring.
    ///
    /// - Parameter value: A substring containing an IRI reference.
    /// - Throws: `IRIError.invalidIRIReference` when the value is not an IRI reference.
    public init(_ value: Substring) throws {
        try self.init(validating: String(value))
    }
}
