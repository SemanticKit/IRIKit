import Testing

extension Tag {
    /// Tests of RFC 3987 section 5.3 normalization.
    @Tag static var normalization: Self

    /// Tests that carry over a behaviour of the URIKit normalizer.
    @Tag static var uriKitParity: Self
}
