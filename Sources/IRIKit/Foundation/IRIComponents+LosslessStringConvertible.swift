extension IRIComponents: LosslessStringConvertible {
    /// Creates component values by parsing an absolute IRI string.
    ///
    /// - Parameter description: The IRI character sequence to parse.
    public init?(_ description: String) {
        guard let iri = try? IRI(validating: description) else {
            return nil
        }

        self.init(
            scheme: iri.scheme,
            authority: iri.authority,
            path: iri.path,
            query: iri.query,
            fragment: iri.fragment
        )
    }
}
