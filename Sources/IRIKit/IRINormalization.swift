/// The RFC 3987 section 5.3 normalization steps applied before comparing IRIs.
///
/// `IRI` equality is simple string comparison (RFC 3987 section 5.3.1). Use
/// an `IRINormalization` value with ``IRI/normalized(_:)`` or
/// ``IRI/isEquivalent(to:under:)`` when a comparison should also treat
/// spelling variants of the same identifier as equal.
///
/// Normalized forms are for local comparison. RFC 3987 section 5.3.2.3
/// requires the original form to be preserved when an IRI is passed on, so
/// keep the value you received and compare normalized copies.
public struct IRINormalization: OptionSet, Hashable, Sendable {
    /// The raw bit set of normalization steps.
    public let rawValue: UInt8

    /// Creates a set of normalization steps from a raw bit set.
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    /// Case normalization (RFC 3987 section 5.3.2.1).
    ///
    /// Lowercases the scheme and a host that contains only US-ASCII
    /// characters, and uppercases the hexadecimal digits of every
    /// percent-encoding triplet.
    public static let letterCase = IRINormalization(rawValue: 1 << 0)

    /// Percent-encoding normalization (RFC 3987 section 5.3.2.3).
    ///
    /// Decodes percent-encoded octet sequences that correspond to
    /// `iunreserved` characters: ASCII letters, digits, `-`, `.`, `_`, `~`,
    /// and the UTF-8 encoding of a `ucschar`. Encoded reserved characters,
    /// private-use characters, and bidirectional formatting characters stay
    /// encoded.
    public static let percentEncoding = IRINormalization(rawValue: 1 << 1)

    /// Path segment normalization (RFC 3987 section 5.3.2.4).
    ///
    /// Removes `.` and `..` segments with the `remove_dot_segments`
    /// algorithm from RFC 3986 section 5.2.4. Empty segments are kept.
    public static let pathSegments = IRINormalization(rawValue: 1 << 2)

    /// Character normalization to Unicode Normalization Form C (RFC 3987
    /// section 5.3.2.2).
    ///
    /// RFC 3987 says equivalence must assume IRIs are already
    /// character-normalized, so this step is not part of
    /// ``syntaxBased``. Use it only where the RFC allows it: when text was
    /// converted from a non-digital form or from a non-UCS character
    /// encoding.
    public static let characters = IRINormalization(rawValue: 1 << 3)

    /// Scheme-based normalization (RFC 3987 section 5.3.3).
    ///
    /// Applies to the `http`, `https`, `ws`, `wss`, and `ftp` schemes, which
    /// use the generic authority syntax with a DNS host and a default port.
    /// For those schemes it:
    ///
    /// - requires a non-empty host, and throws ``IRIError/invalidIRI(_:)``
    ///   when the host is missing;
    /// - removes an empty port or the scheme's default port (`80` for `http`
    ///   and `ws`, `443` for `https` and `wss`, `21` for `ftp`);
    /// - replaces an empty path with `/`;
    /// - decodes Punycode (`xn--`) host labels to Unicode, lowercases them,
    ///   and maps them to Normalization Form KC, so that an IDN and its ACE
    ///   form compare equal while the normal form stays legible.
    ///
    /// IRIs with any other scheme are left unchanged by this step. Delimiters
    /// of empty queries and fragments are never removed.
    public static let scheme = IRINormalization(rawValue: 1 << 4)

    /// Syntax-based normalization (RFC 3987 section 5.3.2): case,
    /// percent-encoding, and path segment normalization.
    public static let syntaxBased: IRINormalization = [.letterCase, .percentEncoding, .pathSegments]

    /// Syntax-based normalization followed by scheme-based normalization.
    public static let syntaxAndSchemeBased: IRINormalization = [.syntaxBased, .scheme]
}
