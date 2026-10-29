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
    /// algorithm of RFC 3986 section 5.2.4, exactly as written, so a
    /// rootless path such as `foo:a/../b` becomes `foo:/b`. Empty segments
    /// are kept. When there is no authority and the result would begin with
    /// `//`, the path is left unchanged, because RFC 3986 section 3.3 forbids
    /// such a path: the text would read as an authority.
    public static let pathSegments = IRINormalization(rawValue: 1 << 2)

    /// Character normalization to Unicode Normalization Form C (RFC 3987
    /// section 5.3.2.2).
    ///
    /// RFC 3987 says equivalence must assume IRIs are already
    /// character-normalized, so this step is not part of
    /// ``syntaxBased``. Use it only where the RFC allows it: when text was
    /// converted from a non-digital form or from a non-UCS character
    /// encoding. NFC uses the Unicode 18.0.0 data that IRIKit carries.
    ///
    /// NFC runs on the text between percent-encoded triplets, which stand
    /// for octets (RFC 3986 section 2.1) and are kept. A character that NFC
    /// produces and the component does not allow, such as the U+0060 that
    /// U+1FEF decomposes to, is percent-encoded as UTF-8 (RFC 3987
    /// section 3.1), so this step never makes a valid IRI invalid.
    public static let characters = IRINormalization(rawValue: 1 << 3)

    /// Scheme-based normalization (RFC 3987 section 5.3.3).
    ///
    /// Applies to the `http` and `https` schemes (RFC 9110 sections 4.2.1 to
    /// 4.2.3), the `ws` and `wss` schemes (RFC 6455 section 3), and the `ftp`
    /// scheme (RFC 1738 sections 3.1, 3.2 and 5). Each of these
    /// specifications requires a host, defines a default port, and makes an
    /// empty path equivalent to `/`. For those schemes this step:
    ///
    /// - requires a non-empty host, and throws ``IRIError/invalidIRI(_:)``
    ///   when the host is missing;
    /// - removes leading zeros from the port, which RFC 3986 section 3.2.3
    ///   defines as a number in decimal;
    /// - removes an empty port or the scheme's default port (`80` for `http`
    ///   and `ws`, `443` for `https` and `wss`, `21` for `ftp`);
    /// - replaces an empty path with `/`;
    /// - validates a registered-name host with IDNA ToASCII (RFC 3490) and,
    ///   when every label is valid, replaces each label with its Nameprep
    ///   (RFC 3491) form, decoding Punycode (`xn--`) labels, so that an IDN
    ///   and its ACE form compare equal while the normal form stays legible.
    ///   The host is split at the four label separators of RFC 3490
    ///   section 3.1. A host that is not a valid IDN keeps its characters.
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
