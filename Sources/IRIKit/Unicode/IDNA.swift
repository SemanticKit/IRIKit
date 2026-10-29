/// The IDNA ToASCII and ToUnicode operations of RFC 3490 section 4, which
/// RFC 3987 section 3.1 and section 5.3.3 use for IDN host labels.
///
/// Both operations use the flags RFC 3987 section 3.1 sets for every use
/// other than creating an IRI: UseSTD3ASCIIRules is TRUE and
/// AllowUnassigned is TRUE.
enum IDNA {
    /// The four characters RFC 3490 section 3.1 requirement 1 says MUST be
    /// recognized as label separators: U+002E FULL STOP, U+3002 IDEOGRAPHIC
    /// FULL STOP, U+FF0E FULLWIDTH FULL STOP and U+FF61 HALFWIDTH
    /// IDEOGRAPHIC FULL STOP.
    static func isLabelSeparator(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x2E, 0x3002, 0xFF0E, 0xFF61: true
        default: false
        }
    }

    /// The ACE prefix of RFC 3490 section 5.
    private static let acePrefix: [Unicode.Scalar] = ["x", "n", "-", "-"]

    /// The longest label, in code points (RFC 3490 section 4.1 step 8).
    private static let maximumLabelLength = 63

    /// ToASCII (RFC 3490 section 4.1). Returns `nil` when the operation
    /// fails.
    static func toASCII(_ label: [Unicode.Scalar]) -> [Unicode.Scalar]? {
        // Step 1 and 2: Nameprep a label that has a non-ASCII code point.
        var sequence = label
        if !sequence.allSatisfy(\.isASCII) {
            guard let prepared = Nameprep.prepare(sequence) else {
                return nil
            }
            sequence = prepared
        }

        // Step 3: UseSTD3ASCIIRules.
        guard !sequence.contains(where: isNonLDHASCII),
            sequence.first != "-",
            sequence.last != "-"
        else {
            return nil
        }

        // Step 4: an ASCII sequence skips to step 8.
        if !sequence.allSatisfy(\.isASCII) {
            // Step 5.
            guard !hasACEPrefix(sequence) else {
                return nil
            }
            // Step 8 bounds the result to 63 code points, and Punycode
            // writes each basic code point once and at least one digit for
            // each other code point, so a longer sequence cannot succeed.
            // Rejecting it here gives the result of step 8 without the
            // quadratic encoding cost.
            guard sequence.count + acePrefix.count <= maximumLabelLength else {
                return nil
            }
            // Steps 6 and 7.
            guard let encoded = Punycode.encode(sequence) else {
                return nil
            }
            sequence = acePrefix + encoded
        }

        // Step 8.
        guard (1...maximumLabelLength).contains(sequence.count) else {
            return nil
        }
        return sequence
    }

    /// ToUnicode (RFC 3490 section 4.2). It never fails: on any failure it
    /// returns its input.
    static func toUnicode(_ label: [Unicode.Scalar]) -> [Unicode.Scalar] {
        // Steps 1 and 2.
        var sequence = label
        if !sequence.allSatisfy(\.isASCII) {
            guard let prepared = Nameprep.prepare(sequence) else {
                return label
            }
            sequence = prepared
        }

        // Step 3.
        guard hasACEPrefix(sequence) else {
            return label
        }
        let saved = sequence

        // Steps 4 and 5.
        guard let decodedScalars = Punycode.decode(Array(sequence.dropFirst(acePrefix.count))) else {
            return label
        }

        // Steps 6 and 7.
        guard let reencoded = toASCII(decodedScalars),
            asciiCaseInsensitiveEqual(reencoded, saved)
        else {
            return label
        }

        // Step 8.
        return decodedScalars
    }

    private static func hasACEPrefix(_ sequence: [Unicode.Scalar]) -> Bool {
        sequence.count >= acePrefix.count
            && asciiCaseInsensitiveEqual(Array(sequence.prefix(acePrefix.count)), acePrefix)
    }

    private static func asciiCaseInsensitiveEqual(_ lhs: [Unicode.Scalar], _ rhs: [Unicode.Scalar]) -> Bool {
        lhs.count == rhs.count && zip(lhs, rhs).allSatisfy { asciiLowercased($0) == asciiLowercased($1) }
    }

    /// Lowercases an ASCII letter and leaves every other code point as it is.
    static func asciiLowercased(_ scalar: Unicode.Scalar) -> Unicode.Scalar {
        (0x41...0x5A).contains(scalar.value) ? Unicode.Scalar(scalar.value + 0x20)! : scalar
    }

    /// The ASCII code points other than letters, digits and hyphen-minus
    /// (RFC 3490 section 4.1 step 3: 0..2C, 2E..2F, 3A..40, 5B..60 and
    /// 7B..7F).
    private static func isNonLDHASCII(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x30...0x39, 0x41...0x5A, 0x61...0x7A, 0x2D: false
        case 0x00...0x7F: true
        default: false
        }
    }
}
