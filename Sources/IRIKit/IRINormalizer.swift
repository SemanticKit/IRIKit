import Foundation

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
            path = removingDotSegments(from: path)
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

    // MARK: - Character and IDN normalization

    private static func nfc(_ string: String) -> String {
        string.precomposedStringWithCanonicalMapping
    }

    /// Normalizes a DNS host for comparison: Punycode labels are decoded,
    /// and each label is lowercased and mapped to NFKC, which are the case
    /// folding and normalization steps of Nameprep (RFC 3491).
    private static func domainNameNormalized(_ host: String) -> String {
        host.split(separator: ".", omittingEmptySubsequences: false)
            .map { domainLabelNormalized(String($0)) }
            .joined(separator: ".")
    }

    private static func domainLabelNormalized(_ label: String) -> String {
        var unicodeLabel = label
        let lowercasedLabel = asciiLowercased(label)
        // IDNA ToUnicode (RFC 3490 section 4.2): a label is only replaced
        // when it decodes to non-ASCII text that encodes back to the same
        // ACE label.
        let encodedPart = String(lowercasedLabel.dropFirst(4))
        if lowercasedLabel.hasPrefix("xn--"),
            let decoded = Punycode.decode(encodedPart),
            !decoded.unicodeScalars.allSatisfy(\.isASCII),
            Punycode.encode(decoded) == encodedPart,
            isRegisteredNameText(decoded)
        {
            unicodeLabel = decoded
        }

        let mapped = unicodeLabel.lowercased().precomposedStringWithCompatibilityMapping
        let candidate = isSafeCompatibilityMapping(mapped, of: unicodeLabel) ? mapped : asciiLowercased(unicodeLabel)
        return uppercasingPercentEncodings(candidate)
    }

    /// Accepts an NFKC-mapped label only when it is still `ireg-name` text
    /// and introduces no percent sign. NFKC maps U+FF05 FULLWIDTH PERCENT
    /// SIGN to `%`, which would either make the host invalid or let a
    /// literal character read as an encoded octet (RFC 3987 section 8).
    private static func isSafeCompatibilityMapping(_ mapped: String, of label: String) -> Bool {
        guard isRegisteredNameText(mapped) else {
            return false
        }
        let percentCount = { (text: String) in text.unicodeScalars.filter { $0 == "%" }.count }
        guard percentCount(mapped) == percentCount(label) else {
            return false
        }
        let scalars = Array(mapped.unicodeScalars)
        for index in scalars.indices where scalars[index] == "%" {
            guard index + 2 < scalars.count,
                hexValue(scalars[index + 1]) != nil,
                hexValue(scalars[index + 2]) != nil
            else {
                return false
            }
        }
        return true
    }

    private static func isRegisteredNameText(_ string: String) -> Bool {
        string.unicodeScalars.allSatisfy { scalar in
            (IRIParser.isIUnreserved(scalar) || IRIParser.isSubDelimiter(scalar) || scalar == "%")
                && !IRIParser.isBidiFormattingCharacter(scalar)
        }
    }
}
