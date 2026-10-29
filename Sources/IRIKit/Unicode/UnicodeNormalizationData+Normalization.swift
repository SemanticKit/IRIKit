// The Unicode Normalization Forms algorithm (Unicode Standard Annex #15,
// section 3 "Definitions" D104 to D117), including the Hangul syllable
// decomposition and composition of The Unicode Standard section 3.12.

extension UnicodeNormalizationData {
    /// Returns the text in the given normalization form.
    func normalized(_ scalars: some Sequence<Unicode.Scalar>, _ form: UnicodeNormalizationForm) -> [Unicode.Scalar] {
        var buffer = decomposed(scalars, compatibility: form.usesCompatibilityDecomposition)
        reorderCanonically(&buffer)
        if form.composes {
            compose(&buffer)
        }
        return buffer.map { Unicode.Scalar($0)! }
    }

    /// Returns the text in the given normalization form.
    func normalized(_ string: String, _ form: UnicodeNormalizationForm) -> String {
        var result = String.UnicodeScalarView()
        result.append(contentsOf: normalized(string.unicodeScalars, form))
        return String(result)
    }

    // MARK: - Decomposition (D68, D65)

    private func decomposed(_ scalars: some Sequence<Unicode.Scalar>, compatibility: Bool) -> [UInt32] {
        var result: [UInt32] = []
        for scalar in scalars {
            let value = scalar.value
            if Hangul.isSyllable(value) {
                Hangul.decompose(value, into: &result)
            } else if let mapping = decomposition(of: value, compatibility: compatibility) {
                result.append(contentsOf: mapping)
            } else {
                result.append(value)
            }
        }
        return result
    }

    // MARK: - Canonical Ordering Algorithm (D109)

    /// Sorts each run of non-starters by canonical combining class, keeping
    /// the order of characters that have the same class.
    private func reorderCanonically(_ buffer: inout [UInt32]) {
        var index = 1
        while index < buffer.count {
            let currentClass = combiningClass(of: buffer[index])
            if currentClass != 0 {
                var position = index
                while position > 0 {
                    let previousClass = combiningClass(of: buffer[position - 1])
                    guard previousClass > currentClass else {
                        break
                    }
                    buffer.swapAt(position, position - 1)
                    position -= 1
                }
            }
            index += 1
        }
    }

    // MARK: - Canonical Composition Algorithm (D117)

    /// Replaces each unblocked pair of a starter and a following character
    /// with their primary composite.
    ///
    /// A character C is blocked from the last starter S when some character
    /// B between them has canonical combining class 0 or a class greater than
    /// or equal to C's (D115). The buffer is in canonical order, so the
    /// character just before C decides whether C is blocked.
    private func compose(_ buffer: inout [UInt32]) {
        var result: [UInt32] = []
        result.reserveCapacity(buffer.count)
        var starterIndex: Int?

        for value in buffer {
            let currentClass = combiningClass(of: value)
            if let starter = starterIndex {
                let isAdjacent = result.count - 1 == starter
                let previousClass = isAdjacent ? 0 : combiningClass(of: result[result.count - 1])
                let isBlocked = !isAdjacent && (previousClass == 0 || previousClass >= currentClass)
                if !isBlocked, let composite = composite(of: result[starter], value) {
                    result[starter] = composite
                    continue
                }
            }
            if currentClass == 0 {
                starterIndex = result.count
            }
            result.append(value)
        }
        buffer = result
    }

    private func composite(of first: UInt32, _ second: UInt32) -> UInt32? {
        Hangul.compose(first, second) ?? primaryComposite(of: first, second)
    }
}

/// The conjoining jamo behavior of The Unicode Standard section 3.12.
private enum Hangul {
    static let sBase: UInt32 = 0xAC00
    static let lBase: UInt32 = 0x1100
    static let vBase: UInt32 = 0x1161
    static let tBase: UInt32 = 0x11A7
    static let lCount: UInt32 = 19
    static let vCount: UInt32 = 21
    static let tCount: UInt32 = 28
    static let nCount = vCount * tCount
    static let sCount = lCount * nCount

    static func isSyllable(_ value: UInt32) -> Bool {
        value >= sBase && value < sBase + sCount
    }

    static func decompose(_ value: UInt32, into result: inout [UInt32]) {
        let index = value - sBase
        result.append(lBase + index / nCount)
        result.append(vBase + (index % nCount) / tCount)
        let trailing = index % tCount
        if trailing != 0 {
            result.append(tBase + trailing)
        }
    }

    static func compose(_ first: UInt32, _ second: UInt32) -> UInt32? {
        if first >= lBase, first < lBase + lCount, second >= vBase, second < vBase + vCount {
            return sBase + ((first - lBase) * vCount + (second - vBase)) * tCount
        }
        if isSyllable(first), (first - sBase) % tCount == 0, second > tBase, second < tBase + tCount {
            return first + (second - tBase)
        }
        return nil
    }
}
