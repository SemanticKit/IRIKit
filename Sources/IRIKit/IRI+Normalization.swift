extension IRI {
    /// Returns the normal form of this IRI under the given RFC 3987
    /// section 5.3 normalization steps.
    ///
    /// The receiver is not changed. RFC 3987 requires the original form to be
    /// preserved when an IRI is passed on, so use the normalized value for
    /// local comparison and keep the original for output.
    ///
    /// ```swift
    /// let iri = try IRI(validating: "HTTP://www.EXAMPLE.com/a/./b/../%7euser")
    ///
    /// try iri.normalized().rawValue
    /// // "http://www.example.com/a/~user"
    /// ```
    ///
    /// - Parameter normalization: The normalization steps to apply. The
    ///   default is ``IRINormalization/syntaxBased``.
    /// - Returns: The normalized IRI.
    /// - Throws: ``IRIError/invalidIRI(_:)`` when
    ///   ``IRINormalization/scheme`` is requested and the scheme requires a
    ///   host that the IRI does not have, such as `https:/relative`.
    public func normalized(_ normalization: IRINormalization = .syntaxBased) throws -> IRI {
        try IRI(validating: normalizedString(normalization))
    }

    /// Returns whether this IRI and another IRI have the same normal form.
    ///
    /// Use `==` for simple string comparison (RFC 3987 section 5.3.1) and
    /// this method to move along the comparison ladder of RFC 3987
    /// section 5.3 with fewer false negatives.
    ///
    /// ```swift
    /// let lhs = try IRI(validating: "example://a/b/c/%7Bfoo%7D/rosé")
    /// let rhs = try IRI(validating: "eXAMPLE://a/./b/../b/%63/%7bfoo%7d/ros%C3%A9")
    ///
    /// lhs == rhs
    /// // false
    ///
    /// try lhs.isEquivalent(to: rhs)
    /// // true
    /// ```
    ///
    /// - Parameters:
    ///   - other: The IRI to compare with.
    ///   - normalization: The normalization steps applied to both IRIs. The
    ///     default is ``IRINormalization/syntaxBased``.
    /// - Throws: ``IRIError/invalidIRI(_:)`` when either IRI cannot be
    ///   normalized under `normalization`.
    public func isEquivalent(
        to other: IRI,
        under normalization: IRINormalization = .syntaxBased
    ) throws -> Bool {
        try normalized(normalization) == other.normalized(normalization)
    }

    private func normalizedString(_ normalization: IRINormalization) throws -> String {
        try IRINormalizer.normalizedString(
            of: ParsedIRIComponents(
                scheme: scheme,
                authority: authority,
                path: path,
                query: query,
                fragment: fragment
            ),
            original: rawValue,
            normalization: normalization
        )
    }
}
