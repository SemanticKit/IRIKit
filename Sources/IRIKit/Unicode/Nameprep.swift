/// The Nameprep profile of stringprep (RFC 3491), which IDNA ToASCII
/// (RFC 3490 section 4.1) applies to a label.
///
/// The steps are the ones RFC 3454 section 3 to 6 define, with the profile
/// choices of RFC 3491 sections 3 to 7:
///
/// 1. Map: remove the characters of table B.1 and case-fold with table B.2
///    (for example `ß` to `ss` and U+210C BLACK-LETTER CAPITAL H to `h`).
/// 2. Normalize: Unicode Normalization Form KC, using Unicode 3.2.
/// 3. Prohibit: reject output that contains a character of tables C.1.2,
///    C.2.2, C.3, C.4, C.5, C.6, C.7, C.8 or C.9.
/// 4. Check bidi: reject output that mixes table D.1 (RandALCat) and table
///    D.2 (LCat) characters, or that contains a RandALCat character without
///    starting and ending with one.
///
/// Unassigned code points (table A.1) are allowed, because RFC 3987
/// section 3.1 sets the AllowUnassigned flag to TRUE for every use other
/// than creating an IRI, and comparison does not create one.
enum Nameprep {
    /// Returns the prepared label, or `nil` when stringprep fails.
    static func prepare(_ label: [Unicode.Scalar]) -> [Unicode.Scalar]? {
        var mapped: [Unicode.Scalar] = []
        mapped.reserveCapacity(label.count)
        for scalar in label {
            if tableB1.contains(scalar.value) {
                continue
            }
            if let folding = tableB2[scalar.value] {
                mapped.append(contentsOf: folding.map { Unicode.Scalar($0)! })
            } else {
                mapped.append(scalar)
            }
        }

        let normalized = UnicodeNormalizationData.unicode3_2.normalized(mapped, .nfkc)

        guard !normalized.contains(where: { isInRanges($0.value, prohibitedRanges) }) else {
            return nil
        }

        let containsRandALCat = normalized.contains { isInRanges($0.value, randALCatRanges) }
        if containsRandALCat {
            guard !normalized.contains(where: { isInRanges($0.value, lCatRanges) }),
                let first = normalized.first, isInRanges(first.value, randALCatRanges),
                let last = normalized.last, isInRanges(last.value, randALCatRanges)
            else {
                return nil
            }
        }

        return normalized
    }

    private static let tableB1 = Set(mappedToNothing)

    private static let tableB2: [UInt32: [UInt32]] = {
        var table: [UInt32: [UInt32]] = [:]
        var position = 0
        while position < caseFoldingForNFKC.count {
            let header = caseFoldingForNFKC[position]
            let count = Int(header >> 21)
            table[header & 0x1F_FFFF] = Array(caseFoldingForNFKC[(position + 1)..<(position + 1 + count)])
            position += 1 + count
        }
        return table
    }()

    /// Whether a code point lies in one of the sorted, disjoint inclusive
    /// ranges stored as pairs of first and last code point.
    static func isInRanges(_ value: UInt32, _ ranges: [UInt32]) -> Bool {
        var low = 0
        var high = ranges.count / 2
        while low < high {
            let middle = (low + high) / 2
            if value < ranges[middle * 2] {
                high = middle
            } else if value > ranges[middle * 2 + 1] {
                low = middle + 1
            } else {
                return true
            }
        }
        return false
    }
}
