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
    ///   ``IRIError/normalFormHasNoText(_:)`` when the normal form cannot be
    ///   written as IRI text: there is no authority and
    ///   ``IRINormalization/pathSegments`` gives a path that begins with
    ///   `//`. Use ``isEquivalent(to:under:)`` to compare such an IRI.
    public func normalized(_ normalization: IRINormalization = .syntaxBased) throws -> AbsoluteIRI {
        guard let text = try normalizedComponents(normalization).recomposed else {
            throw IRIError.normalFormHasNoText(rawValue)
        }
        return try AbsoluteIRI(validating: text)
    }

    /// Returns whether this absolute IRI and another absolute IRI have the
    /// same normal form.
    ///
    /// The method compares the normalized components (RFC 3986
    /// section 6.2.2), so it is defined for every absolute IRI, including
    /// one whose normal form has no text.
    ///
    /// - Parameters:
    ///   - other: The absolute IRI to compare with.
    ///   - normalization: The normalization steps applied to both IRIs. The
    ///     default is ``IRINormalization/syntaxBased``.
    /// - Throws: ``IRIError/invalidIRI(_:)`` when
    ///   ``IRINormalization/scheme`` is requested and the scheme of either
    ///   IRI requires a host that the IRI does not have.
    public func isEquivalent(
        to other: AbsoluteIRI,
        under normalization: IRINormalization = .syntaxBased
    ) throws -> Bool {
        try normalizedComponents(normalization) == other.normalizedComponents(normalization)
    }

    private func normalizedComponents(_ normalization: IRINormalization) throws -> NormalizedIRIComponents {
        try IRINormalizer.normalizedComponents(
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
    }
}
