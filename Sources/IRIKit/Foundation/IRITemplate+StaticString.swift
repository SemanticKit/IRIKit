extension IRITemplate {
    /// Creates an IRI template from a static string.
    ///
    /// - Parameter value: A static string containing an IRI template.
    /// - Throws: `IRIError.invalidTemplate` when the value is not a valid template.
    public init(_ value: StaticString) throws {
        try self.init(validating: value.description)
    }
}
