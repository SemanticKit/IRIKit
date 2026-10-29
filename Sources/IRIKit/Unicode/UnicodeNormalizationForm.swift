/// A Unicode Normalization Form (Unicode Standard Annex #15 section 1.2).
enum UnicodeNormalizationForm: Sendable, CaseIterable {
    /// Canonical decomposition.
    case nfd

    /// Canonical decomposition followed by canonical composition.
    case nfc

    /// Compatibility decomposition.
    case nfkd

    /// Compatibility decomposition followed by canonical composition.
    case nfkc

    var usesCompatibilityDecomposition: Bool {
        self == .nfkd || self == .nfkc
    }

    var composes: Bool {
        self == .nfc || self == .nfkc
    }
}
