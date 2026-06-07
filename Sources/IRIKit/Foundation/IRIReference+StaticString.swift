extension IRIReference {
    /// Creates an IRI reference from a static string.
    ///
    /// - Parameter value: A static string containing an IRI reference.
    /// - Throws: `IRIError.invalidIRIReference` when the value is not an IRI reference.
    public init(_ value: StaticString) throws {
        try self.init(validating: value.description)
    }
}
