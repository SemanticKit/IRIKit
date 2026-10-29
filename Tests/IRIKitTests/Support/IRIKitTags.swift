import Testing

extension Tag {
    /// Tests of RFC 3987 section 5.3 normalization.
    @Tag static var normalization: Self

    /// Tests that carry over a behaviour of the URIKit normalizer.
    @Tag static var uriKitParity: Self
}

extension Tag {
    /// Tests of the Unicode Normalization Forms (UAX #15).
    @Tag static var unicodeNormalization: Self

    /// Tests of IDNA ToASCII and ToUnicode (RFC 3490) and Nameprep (RFC 3491).
    @Tag static var idna: Self
}

extension Tag {
    /// Tests that sweep every code point. They are the proofs for the label
    /// mapping and table properties and the slowest tests in the package.
    /// The tag marks them in test reports and in Xcode's test navigator; the
    /// full suite always runs them.
    @Tag static var exhaustive: Self
}
