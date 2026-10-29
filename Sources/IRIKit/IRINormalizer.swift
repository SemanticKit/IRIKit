/// Applies RFC 3987 section 5.3 normalization to validated IRI components.
enum IRINormalizer {
    static func normalizedString(
        of components: ParsedIRIComponents,
        original: String,
        normalization: IRINormalization
    ) throws -> String {
        var scheme = components.scheme
        var authority = components.authority.map(IRIAuthorityParts.init)
        var path = components.path
        var query = components.query
        var fragment = components.fragment

        func transformText(_ transform: (String) -> String) {
            authority?.transformText(transform)
            path = transform(path)
            query = query.map(transform)
            fragment = fragment.map(transform)
        }

        if normalization.contains(.percentEncoding) {
            transformText(decodingUnreserved)
        }

        // NFC runs after percent-encoding decoding, so text that decoding
        // produced is in NFC too and the result is a fixed point.
        if normalization.contains(.characters) {
            transformText(nfc)
        }

        if normalization.contains(.letterCase) {
            scheme = asciiLowercased(scheme)
            if var parts = authority, parts.host.unicodeScalars.allSatisfy(\.isASCII) {
                parts.host = asciiLowercased(parts.host)
                authority = parts
            }
            transformText(uppercasingPercentEncodings)
        }

        if normalization.contains(.pathSegments) {
            path = pathRemovingDotSegments(path)
        }

        if normalization.contains(.scheme), let rule = IRISchemeNormalizationRule(scheme: scheme) {
            guard var parts = authority, !parts.host.isEmpty else {
                throw IRIError.invalidIRI(original)
            }

            if let port = parts.port, port.isEmpty || Int(port) == rule.defaultPort {
                parts.port = nil
            }
            if !parts.isIPLiteral {
                parts.host = domainNameNormalized(parts.host)
            }
            authority = parts

            if path.isEmpty {
                path = "/"
            }
        }

        if authority == nil, path.hasPrefix("//") {
            // Keep a path that dot-segment removal left starting with "//"
            // from being read as an authority (RFC 3986 section 5.2.4).
            path = "/." + path
        }

        var result = scheme + ":"
        if let authority {
            result += "//" + authority.string
        }
        result += path
        if let query {
            result += "?" + query
        }
        if let fragment {
            result += "#" + fragment
        }
        return result
    }

    // MARK: - Case normalization

    private static func asciiLowercased(_ string: String) -> String {
        var result = ""
        result.unicodeScalars.append(contentsOf: string.unicodeScalars.map { scalar in
            (0x41...0x5A).contains(scalar.value) ? Unicode.Scalar(scalar.value + 0x20)! : scalar
        })
        return result
    }

    static func uppercasingPercentEncodings(_ string: String) -> String {
        var scalars = Array(string.unicodeScalars)
        var index = 0
        while index + 2 < scalars.count {
            if scalars[index] == "%" {
                for offset in 1...2 where (0x61...0x66).contains(scalars[index + offset].value) {
                    scalars[index + offset] = Unicode.Scalar(scalars[index + offset].value - 0x20)!
                }
                index += 3
            } else {
                index += 1
            }
        }
        var result = ""
        result.unicodeScalars.append(contentsOf: scalars)
        return result
    }

    // MARK: - Percent-encoding normalization

    static func decodingUnreserved(_ string: String) -> String {
        let scalars = Array(string.unicodeScalars)
        var result = String.UnicodeScalarView()
        var index = 0

        while index < scalars.count {
            guard scalars[index] == "%", let lead = byte(in: scalars, at: index) else {
                result.append(scalars[index])
                index += 1
                continue
            }

            let length = utf8SequenceLength(lead)
            var bytes = [lead]
            var cursor = index + 3
            while bytes.count < length, let next = byte(in: scalars, at: cursor), next & 0xC0 == 0x80 {
                bytes.append(next)
                cursor += 3
            }

            if bytes.count == length,
                let scalar = decodeUTF8(bytes),
                isDecodable(scalar)
            {
                result.append(scalar)
                index = cursor
            } else {
                result.append(contentsOf: scalars[index..<(index + 3)])
                index += 3
            }
        }

        return String(result)
    }

    private static func isDecodable(_ scalar: Unicode.Scalar) -> Bool {
        IRIParser.isIUnreserved(scalar) && !IRIParser.isBidiFormattingCharacter(scalar)
    }

    private static func byte(in scalars: [Unicode.Scalar], at index: Int) -> UInt8? {
        guard index + 2 < scalars.count,
            scalars[index] == "%",
            let high = hexValue(scalars[index + 1]),
            let low = hexValue(scalars[index + 2])
        else {
            return nil
        }
        return high << 4 | low
    }

    private static func utf8SequenceLength(_ lead: UInt8) -> Int {
        switch lead {
        case 0x00...0x7F: 1
        case 0xC2...0xDF: 2
        case 0xE0...0xEF: 3
        case 0xF0...0xF4: 4
        default: 0
        }
    }

    private static func decodeUTF8(_ bytes: [UInt8]) -> Unicode.Scalar? {
        var decoder = Unicode.UTF8()
        var iterator = bytes.makeIterator()
        guard case .scalarValue(let scalar) = decoder.decode(&iterator),
            case .emptyInput = decoder.decode(&iterator)
        else {
            return nil
        }
        return scalar
    }

    private static func hexValue(_ scalar: Unicode.Scalar) -> UInt8? {
        switch scalar.value {
        case 0x30...0x39: UInt8(scalar.value - 0x30)
        case 0x41...0x46: UInt8(scalar.value - 0x41 + 10)
        case 0x61...0x66: UInt8(scalar.value - 0x61 + 10)
        default: nil
        }
    }

    // MARK: - Path segment normalization

    /// The `remove_dot_segments` algorithm from RFC 3986 section 5.2.4.
    static func removingDotSegments(from path: String) -> String {
        var input = Substring(path)
        var output = ""

        func removeLastOutputSegment() {
            if let slash = output.lastIndex(of: "/") {
                output.removeSubrange(slash...)
            } else {
                output.removeAll()
            }
        }

        while !input.isEmpty {
            if input.hasPrefix("../") {
                input.removeFirst(3)
            } else if input.hasPrefix("./") {
                input.removeFirst(2)
            } else if input.hasPrefix("/./") {
                input.removeFirst(2)
            } else if input == "/." {
                input = "/"
            } else if input.hasPrefix("/../") {
                input.removeFirst(3)
                removeLastOutputSegment()
            } else if input == "/.." {
                input = "/"
                removeLastOutputSegment()
            } else if input == "." || input == ".." {
                input.removeAll()
            } else {
                let searchStart = input.hasPrefix("/") ? input.index(after: input.startIndex) : input.startIndex
                let segmentEnd = input[searchStart...].firstIndex(of: "/") ?? input.endIndex
                output += input[..<segmentEnd]
                input = input[segmentEnd...]
            }
        }

        return output
    }

    /// Removes dot segments and keeps the kind of path the input had.
    ///
    /// An absolute or empty path goes through RFC 3986 section 5.2.4 as is.
    /// A rootless path is treated as if it were rooted, then the root is
    /// taken off again, so the result stays rootless. When the result
    /// starts with an empty segment it is written after a "./" segment,
    /// which keeps it from reading as an absolute path and is stable when
    /// normalized again.
    static func pathRemovingDotSegments(_ path: String) -> String {
        guard !path.isEmpty, !path.hasPrefix("/") else {
            return removingDotSegments(from: path)
        }
        var rootless = removingDotSegments(from: "/" + path)
        if rootless.hasPrefix("/") {
            rootless.removeFirst()
        }
        if rootless.hasPrefix("/") {
            rootless = "./" + rootless
        }
        return rootless
    }

    // MARK: - Character and IDN normalization

    private static func nfc(_ string: String) -> String {
        UnicodeNormalizationData.unicode17_0.normalized(string, .nfc)
    }

    /// Normalizes a DNS host for comparison (RFC 3987 section 5.3.3).
    ///
    /// The host is split at the four label separators of RFC 3490
    /// section 3.1, and each label is validated with IDNA ToASCII and mapped
    /// by `domainLabelNormalized(_:)`. A trailing empty label is the root
    /// label, which RFC 3490 section 2 does not count as a label, and stays.
    /// When any label fails ToASCII the host is not a valid IDN, and RFC 3987
    /// section 5.3.3 applies Nameprep only to validated IDN components, so
    /// the host is returned unchanged. Labels are joined with U+002E FULL
    /// STOP, as RFC 3490 section 4 step 4 does after ToASCII.
    static func domainNameNormalized(_ host: String) -> String {
        var labels: [[Unicode.Scalar]] = [[]]
        for scalar in host.unicodeScalars {
            if IDNA.isLabelSeparator(scalar) {
                labels.append([])
            } else {
                labels[labels.count - 1].append(scalar)
            }
        }
        let hasRootLabel = labels.count > 1 && labels[labels.count - 1].isEmpty
        if hasRootLabel {
            labels.removeLast()
        }

        var result = String.UnicodeScalarView()
        for (index, label) in labels.enumerated() {
            guard let normalized = domainLabelNormalized(label) else {
                return host
            }
            if index > 0 {
                result.append(".")
            }
            result.append(contentsOf: normalized)
        }
        if hasRootLabel {
            result.append(".")
        }
        return String(result)
    }

    /// Maps a label to its normal form, or returns `nil` when ToASCII fails.
    ///
    /// The normal form is ToUnicode(ToASCII(label)) with ASCII letters
    /// lowercased: the Nameprep form (RFC 3987 section 5.3.3), kept legible
    /// rather than converted to ACE. When that text would not be a valid
    /// `ireg-name` label, because it contains a label separator or a
    /// character an IRI cannot hold, the lowercased ACE label is the normal
    /// form instead.
    ///
    /// Two labels get the same normal form exactly when their ToASCII
    /// results are equal ignoring ASCII case, which is the label comparison
    /// of RFC 3490 section 3.1 requirement 4. The mapping is idempotent by
    /// construction, so it needs no iteration: when ToUnicode decodes, it has
    /// already checked that ToASCII of the decoded text gives the same ACE
    /// label, so the normal form maps back to the same ToASCII result, and
    /// Nameprep case-folds ASCII letters (table B.2), so lowercasing does not
    /// change that result.
    static func domainLabelNormalized(_ label: [Unicode.Scalar]) -> [Unicode.Scalar]? {
        guard let ascii = IDNA.toASCII(label) else {
            return nil
        }
        let unicode = IDNA.toUnicode(ascii).map(IDNA.asciiLowercased)
        let isLabelText = !unicode.contains(where: IDNA.isLabelSeparator)
            && unicode.allSatisfy { IRIParser.isIUnreserved($0) && !IRIParser.isBidiFormattingCharacter($0) }
        return isLabelText ? unicode : ascii.map(IDNA.asciiLowercased)
    }
}
