extension IRITemplate {
    /// Creates an IRI template from a substring.
    ///
    /// - Parameter value: A substring containing an IRI template.
    /// - Throws: `IRIError.invalidTemplate` when the value is not a valid template.
    public init(_ value: Substring) throws {
        try self.init(validating: String(value))
    }
}
