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
            if var parts = authority {
                parts.userInfo = parts.userInfo.map { characterNormalized($0, allowing: isUserInfoCharacter) }
                if !parts.isIPLiteral {
                    parts.host = characterNormalized(parts.host, allowing: isRegisteredNameCharacter)
                }
                authority = parts
            }
            path = characterNormalized(path, allowing: IRIParser.isPathCharacter)
            query = query.map { characterNormalized($0, allowing: isQueryCharacter) }
            fragment = fragment.map { characterNormalized($0, allowing: isFragmentCharacter) }
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
            let candidate = removingDotSegments(from: path)
            // RFC 3986 section 3.3: when there is no authority, a path cannot
            // begin with "//", because the text would then be read as an
            // authority. remove_dot_segments can produce such a path (for
            // example from "/.//a"); the recomposed text would name a
            // different IRI, and RFC 3987 section 5.1 requires that
            // comparison never produce such a false positive, so the path
            // keeps its dot segments in that case.
            if authority != nil || !candidate.unicodeScalars.starts(with: "//".unicodeScalars) {
                path = candidate
            }
        }

        if normalization.contains(.scheme), let rule = IRISchemeNormalizationRule(scheme: scheme) {
            guard var parts = authority, !parts.host.isEmpty else {
                throw IRIError.invalidIRI(original)
            }

            if let port = parts.port {
                // RFC 3986 section 3.2.3: the port is a number in decimal,
                // and the schemes with a rule use it as a TCP port number,
                // so leading zeros do not change it. The digits are compared
                // as text, so a port of any length is handled.
                let digits = port.unicodeScalars.drop { $0 == "0" }
                let number = digits.isEmpty ? "0" : IRIParser.text(digits)
                parts.port = port.isEmpty || number == String(rule.defaultPort) ? nil : number
            }
            if !parts.isIPLiteral {
                parts.host = domainNameNormalized(parts.host)
            }
            authority = parts

            if path.isEmpty {
                path = "/"
            }
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

    /// The `remove_dot_segments` algorithm of RFC 3986 section 5.2.4, step
    /// for step.
    ///
    /// The algorithm works on characters, so the buffers hold Unicode
    /// scalars: a combining mark after `/` or `.` must not merge with it the
    /// way it would in a `Character`.
    static func removingDotSegments(from path: String) -> String {
        // Step 1: the input buffer holds the path, the output buffer is empty.
        var input = Array(path.unicodeScalars)[...]
        var output: [Unicode.Scalar] = []

        func hasPrefix(_ prefix: String) -> Bool {
            input.starts(with: prefix.unicodeScalars)
        }

        func isExactly(_ text: String) -> Bool {
            input.elementsEqual(text.unicodeScalars)
        }

        // Step 2: while the input buffer is not empty, loop.
        while !input.isEmpty {
            if hasPrefix("../") {
                // 2A: remove the prefix "../".
                input.removeFirst(3)
            } else if hasPrefix("./") {
                // 2A: remove the prefix "./".
                input.removeFirst(2)
            } else if hasPrefix("/./") {
                // 2B: replace the prefix "/./" with "/".
                input.removeFirst(2)
            } else if isExactly("/.") {
                // 2B: replace "/." (a complete path segment) with "/".
                input = ["/"]
            } else if hasPrefix("/../") {
                // 2C: replace the prefix "/../" with "/" and remove the last
                // segment and its preceding "/" (if any) from the output.
                input.removeFirst(3)
                removeLastSegment(from: &output)
            } else if isExactly("/..") {
                // 2C: replace "/.." (a complete path segment) with "/" and
                // remove the last output segment.
                input = ["/"]
                removeLastSegment(from: &output)
            } else if isExactly(".") || isExactly("..") {
                // 2D: remove "." or "..".
                input.removeAll()
            } else {
                // 2E: move the first path segment, with its initial "/" if
                // any, and every character up to the next "/", to the output.
                let searchStart = input.first == "/" ? input.index(after: input.startIndex) : input.startIndex
                let segmentEnd = input[searchStart...].firstIndex(of: "/") ?? input.endIndex
                output.append(contentsOf: input[..<segmentEnd])
                input = input[segmentEnd...]
            }
        }

        // Step 3: the output buffer is the result.
        var result = String.UnicodeScalarView()
        result.append(contentsOf: output)
        return String(result)
    }

    private static func removeLastSegment(from output: inout [Unicode.Scalar]) {
        if let slash = output.lastIndex(of: "/") {
            output.removeSubrange(slash...)
        } else {
            output.removeAll()
        }
    }

    // MARK: - Character and IDN normalization

    /// Applies NFC (RFC 3987 section 5.3.2.2) to the characters of one
    /// component.
    ///
    /// A `pct-encoded` triplet stands for an octet (RFC 3986 section 2.1),
    /// not for the three characters it is written with, so NFC runs on the
    /// text between triplets and every triplet is kept as it is. Otherwise a
    /// combining mark after a triplet would compose with its last hexadecimal
    /// digit, as `%4E` followed by U+0301 would become `%4` and U+0143.
    ///
    /// NFC can map an allowed character to one the component does not allow:
    /// U+1FEF GREEK VARIA has the canonical decomposition U+0060 GRAVE
    /// ACCENT, which no IRI component allows. Such a character is
    /// percent-encoded as the octets of its UTF-8 form, with uppercase
    /// hexadecimal digits, as RFC 3987 section 3.1 step 2 and RFC 3986
    /// section 2.1 encode a character that cannot appear literally, so the
    /// normal form of a valid IRI is always a valid IRI.
    static func characterNormalized(
        _ string: String,
        allowing isAllowed: (Unicode.Scalar) -> Bool
    ) -> String {
        let scalars = Array(string.unicodeScalars)
        var result = String.UnicodeScalarView()
        var run = String.UnicodeScalarView()

        func appendNormalizedRun() {
            guard !run.isEmpty else {
                return
            }
            let normalized = UnicodeNormalizationData.unicode17_0.normalized(String(run), .nfc)
            for scalar in normalized.unicodeScalars {
                if scalar != "%", isAllowed(scalar), !IRIParser.isBidiFormattingCharacter(scalar) {
                    result.append(scalar)
                } else {
                    appendPercentEncoded(scalar, to: &result)
                }
            }
            run = String.UnicodeScalarView()
        }

        var index = 0
        while index < scalars.count {
            if scalars[index] == "%", index + 2 < scalars.count {
                appendNormalizedRun()
                result.append(contentsOf: scalars[index...(index + 2)])
                index += 3
            } else {
                run.append(scalars[index])
                index += 1
            }
        }
        appendNormalizedRun()
        return String(result)
    }

    private static func appendPercentEncoded(_ scalar: Unicode.Scalar, to result: inout String.UnicodeScalarView) {
        let digits = Array("0123456789ABCDEF".unicodeScalars)
        for byte in String(scalar).utf8 {
            result.append("%")
            result.append(digits[Int(byte >> 4)])
            result.append(digits[Int(byte & 0x0F)])
        }
    }

    /// The characters an `iuserinfo` may hold besides `pct-encoded`.
    private static func isUserInfoCharacter(_ scalar: Unicode.Scalar) -> Bool {
        IRIParser.isIUnreserved(scalar) || IRIParser.isSubDelimiter(scalar) || scalar == ":"
    }

    /// The characters an `ireg-name` may hold besides `pct-encoded`.
    private static func isRegisteredNameCharacter(_ scalar: Unicode.Scalar) -> Bool {
        IRIParser.isIUnreserved(scalar) || IRIParser.isSubDelimiter(scalar)
    }

    /// The characters an `iquery` may hold: `ipchar`, `iprivate`, `/` and `?`.
    private static func isQueryCharacter(_ scalar: Unicode.Scalar) -> Bool {
        IRIParser.isPathCharacter(scalar) || IRIParser.isIPrivate(scalar) || scalar == "?"
    }

    /// The characters an `ifragment` may hold: `ipchar`, `/` and `?`.
    private static func isFragmentCharacter(_ scalar: Unicode.Scalar) -> Bool {
        IRIParser.isPathCharacter(scalar) || scalar == "?"
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
