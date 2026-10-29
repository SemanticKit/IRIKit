extension AbsoluteIRI {
    /// Returns the normal form of this absolute IRI under the given
    /// RFC 3987 section 5.3 normalization steps.
    ///
    /// The receiver is not changed. Use the normalized value for local
    /// comparison and keep the original for output.
    ///
    /// ```swift
    /// let iri = try AbsoluteIRI(validating: "HTTPS://Example.com:443")
    ///
    /// try iri.normalized(.syntaxAndSchemeBased).rawValue
    /// // "https://example.com/"
    /// ```
    ///
    /// - Parameter normalization: The normalization steps to apply. The
    ///   default is ``IRINormalization/syntaxBased``.
    /// - Returns: The normalized absolute IRI.
    /// - Throws: ``IRIError/invalidIRI(_:)`` when
    ///   ``IRINormalization/scheme`` is requested and the scheme requires a
    ///   host that the IRI does not have.
    public func normalized(_ normalization: IRINormalization = .syntaxBased) throws -> AbsoluteIRI {
        let string = try IRINormalizer.normalizedString(
            of: ParsedIRIComponents(
                scheme: scheme,
                authority: authority,
                path: path,
                query: query,
                fragment: nil
            ),
            original: rawValue,
            normalization: normalization
        )
        return try AbsoluteIRI(validating: string)
    }

    /// Returns whether this absolute IRI and another absolute IRI have the
    /// same normal form.
    ///
    /// - Parameters:
    ///   - other: The absolute IRI to compare with.
    ///   - normalization: The normalization steps applied to both IRIs. The
    ///     default is ``IRINormalization/syntaxBased``.
    /// - Throws: ``IRIError/invalidIRI(_:)`` when either IRI cannot be
    ///   normalized under `normalization`.
    public func isEquivalent(
        to other: AbsoluteIRI,
        under normalization: IRINormalization = .syntaxBased
    ) throws -> Bool {
        try normalized(normalization) == other.normalized(normalization)
    }
}
