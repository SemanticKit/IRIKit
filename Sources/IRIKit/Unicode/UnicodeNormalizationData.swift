/// The Unicode Character Database properties that the Unicode Normalization
/// Forms (Unicode Standard Annex #15) need, for one version of Unicode.
///
/// The tables are generated from the Unicode Character Database by
/// `Scripts/UnicodeTables/generate.py`. `Scripts/UnicodeTables/sources.json`
/// records the source and version of every input file. IRIKit uses two
/// versions:
///
/// - ``unicode18_0`` for RFC 3987 section 5.3.2.2 character normalization
///   (NFC). The Unicode normalization stability policy keeps the NFC form
///   of text that is assigned in an earlier version unchanged in every later
///   version, so the latest version covers the most text.
/// - ``unicode3_2`` for Nameprep (RFC 3491), because stringprep (RFC 3454
///   section 4) fixes normalization to Unicode 3.2.
struct UnicodeNormalizationData: Sendable {
    /// The Unicode version the data comes from.
    let version: String

    private let combiningClassRanges: [UInt32]
    private let canonicalDecompositions: [UInt32]
    private let compatibilityDecompositions: [UInt32]
    private let canonicalIndex: [UInt32: Range<Int>]
    private let compatibilityIndex: [UInt32: Range<Int>]
    private let composites: [UInt64: UInt32]

    /// Creates the data from generated tables.
    ///
    /// - Parameters:
    ///   - version: The Unicode version.
    ///   - combiningClassRanges: Sorted triples of first code point, last
    ///     code point and nonzero canonical combining class.
    ///   - canonicalDecompositions: Records of a header word (code point |
    ///     count << 21) followed by the full canonical decomposition.
    ///   - compatibilityDecompositions: Records in the same layout with the
    ///     full compatibility decomposition, for the code points where it
    ///     differs from the canonical one.
    ///   - primaryComposites: Triples of first code point, second code
    ///     point and primary composite.
    init(
        version: String,
        combiningClassRanges: [UInt32],
        canonicalDecompositions: [UInt32],
        compatibilityDecompositions: [UInt32],
        primaryComposites: [UInt32]
    ) {
        self.version = version
        self.combiningClassRanges = combiningClassRanges
        self.canonicalDecompositions = canonicalDecompositions
        self.compatibilityDecompositions = compatibilityDecompositions
        canonicalIndex = Self.index(canonicalDecompositions)
        compatibilityIndex = Self.index(compatibilityDecompositions)

        var composites: [UInt64: UInt32] = [:]
        composites.reserveCapacity(primaryComposites.count / 3)
        var position = 0
        while position + 2 < primaryComposites.count {
            composites[Self.pairKey(primaryComposites[position], primaryComposites[position + 1])] =
                primaryComposites[position + 2]
            position += 3
        }
        self.composites = composites
    }

    /// The canonical combining class of a code point.
    func combiningClass(of value: UInt32) -> UInt8 {
        var low = 0
        var high = combiningClassRanges.count / 3
        while low < high {
            let middle = (low + high) / 2
            let start = combiningClassRanges[middle * 3]
            let end = combiningClassRanges[middle * 3 + 1]
            if value < start {
                high = middle
            } else if value > end {
                low = middle + 1
            } else {
                return UInt8(combiningClassRanges[middle * 3 + 2])
            }
        }
        return 0
    }

    /// The full decomposition of a code point that is not a Hangul
    /// syllable, or `nil` when it decomposes to itself.
    func decomposition(of value: UInt32, compatibility: Bool) -> ArraySlice<UInt32>? {
        if compatibility, let range = compatibilityIndex[value] {
            return compatibilityDecompositions[range]
        }
        if let range = canonicalIndex[value] {
            return canonicalDecompositions[range]
        }
        return nil
    }

    /// The primary composite of two code points, if there is one that is not
    /// excluded from composition.
    func primaryComposite(of first: UInt32, _ second: UInt32) -> UInt32? {
        composites[Self.pairKey(first, second)]
    }

    private static func pairKey(_ first: UInt32, _ second: UInt32) -> UInt64 {
        UInt64(first) << 32 | UInt64(second)
    }

    private static func index(_ records: [UInt32]) -> [UInt32: Range<Int>] {
        var index: [UInt32: Range<Int>] = [:]
        var position = 0
        while position < records.count {
            let header = records[position]
            let count = Int(header >> 21)
            index[header & 0x1F_FFFF] = (position + 1)..<(position + 1 + count)
            position += 1 + count
        }
        return index
    }
}
