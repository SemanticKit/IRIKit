/// Validates IRI text against the RFC 3987 section 2.2 grammar.
///
/// The grammar is defined over characters, which RFC 3987 section 2 defines
/// as Unicode code points, so every delimiter search and character test runs
/// on Unicode scalars. A `Character` would join a delimiter such as `/`, `@`
/// or `:` with a combining mark that follows it into one grapheme, and the
/// delimiter would no longer be found.
enum IRIParser {
    typealias Scalars = ArraySlice<Unicode.Scalar>

    static func parseIRI(_ string: String) throws -> ParsedIRIComponents {
        let scalars = Array(string.unicodeScalars)[...]
        guard let schemeEnd = scalars.firstIndex(of: ":") else {
            throw IRIError.invalidIRI(string)
        }

        let scheme = scalars[..<schemeEnd]
        guard isValidScheme(scheme) else {
            throw IRIError.invalidIRI(string)
        }

        do {
            let components = try parseHierPart(scalars[(schemeEnd + 1)...], scheme: text(scheme))
            try validateCharacters(in: components.authority ?? "", allowsPrivate: false)
            try validateAuthority(components.authority)
            try validatePathCharacters(in: components.path)
            try validateCharacters(in: components.query ?? "", allowsPrivate: true)
            try validateCharacters(in: components.fragment ?? "", allowsPrivate: false)
            return components
        } catch IRIError.invalidIRIReference {
            throw IRIError.invalidIRI(string)
        }
    }

    static func parseIRIReference(_ string: String) throws {
        try validateCharacters(in: string, allowsPrivate: false, allowsFragment: true)
        let scalars = Array(string.unicodeScalars)[...]
        if let colon = scalars.firstIndex(of: ":"), isValidScheme(scalars[..<colon]) {
            _ = try parseIRI(string)
        }
    }

    private static func parseHierPart(
        _ rest: Scalars, scheme: String
    ) throws -> ParsedIRIComponents {
        var remaining = rest
        var authority: String?

        if remaining.starts(with: "//".unicodeScalars) {
            remaining = remaining.dropFirst(2)
            let authorityEnd =
                remaining.firstIndex { $0 == "/" || $0 == "?" || $0 == "#" } ?? remaining.endIndex
            // ireg-name = *( iunreserved / pct-encoded / sub-delims ) may be
            // empty, as in file:///etc/hosts.
            authority = text(remaining[..<authorityEnd])
            remaining = remaining[authorityEnd...]
        }

        let fragmentSplit = split(remaining, at: "#")
        let querySplit = split(fragmentSplit.head, at: "?")
        let path = querySplit.head

        if authority == nil, path.starts(with: "//".unicodeScalars) {
            throw IRIError.invalidIRIReference(text(rest))
        }

        return ParsedIRIComponents(
            scheme: scheme,
            authority: authority,
            path: text(path),
            query: querySplit.tail.map(text),
            fragment: fragmentSplit.tail.map(text)
        )
    }

    private static func split(
        _ input: Scalars, at separator: Unicode.Scalar
    ) -> (head: Scalars, tail: Scalars?) {
        guard let index = input.firstIndex(of: separator) else {
            return (input, nil)
        }

        return (input[..<index], input[(index + 1)...])
    }

    static func text(_ scalars: some Sequence<Unicode.Scalar>) -> String {
        var view = String.UnicodeScalarView()
        view.append(contentsOf: scalars)
        return String(view)
    }

    private static func validateCharacters(
        in string: String,
        allowsPrivate: Bool,
        allowsFragment: Bool = false
    ) throws {
        for scalar in string.unicodeScalars {
            guard isAllowed(
                scalar,
                allowsPrivate: allowsPrivate,
                allowsFragment: allowsFragment
            ) else {
                throw IRIError.invalidIRIReference(string)
            }
        }

        try validatePercentEncoding(in: string)
    }

    /// Checks that every `%` starts a `pct-encoded` triplet: `%` and two
    /// `HEXDIG`, which RFC 5234 appendix B.1 defines as ASCII only.
    private static func validatePercentEncoding(in string: String) throws {
        let scalars = Array(string.unicodeScalars)
        var index = 0
        while index < scalars.count {
            guard scalars[index] == "%" else {
                index += 1
                continue
            }

            guard index + 2 < scalars.count,
                isHexDigit(scalars[index + 1]),
                isHexDigit(scalars[index + 2])
            else {
                throw IRIError.invalidIRIReference(string)
            }

            index += 3
        }
    }

    private static func validatePathCharacters(in path: String) throws {
        try validateCharacters(in: path, allowsPrivate: false)

        guard path.unicodeScalars.allSatisfy(isPathCharacter) else {
            throw IRIError.invalidIRIReference(path)
        }
    }

    private static func validateAuthority(_ authority: String?) throws {
        guard let authority else {
            return
        }

        let scalars = Array(authority.unicodeScalars)[...]
        let authorityPieces = scalars.split(separator: "@", omittingEmptySubsequences: false)
        guard authorityPieces.count <= 2 else {
            throw IRIError.invalidIRIReference(authority)
        }

        let hostPort = authorityPieces.last ?? []
        if hostPort.first == "[" {
            try validateIPLiteralHostPort(hostPort, authority: authority)
            return
        }

        guard !hostPort.contains("["),
            !hostPort.contains("]")
        else {
            throw IRIError.invalidIRIReference(authority)
        }

        let pieces = hostPort.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        try validateRegisteredOrIPv4Host(pieces[0], authority: authority)

        guard pieces.count == 2 else {
            return
        }

        guard pieces[1].allSatisfy(isDigit) else {
            throw IRIError.invalidIRIReference(authority)
        }
    }

    private static func validateIPLiteralHostPort(_ hostPort: Scalars, authority: String) throws {
        guard let closingBracket = hostPort.firstIndex(of: "]") else {
            throw IRIError.invalidIRIReference(authority)
        }

        let afterBracket = closingBracket + 1
        guard afterBracket == hostPort.endIndex || hostPort[afterBracket] == ":" else {
            throw IRIError.invalidIRIReference(authority)
        }

        if afterBracket < hostPort.endIndex {
            guard hostPort[(afterBracket + 1)...].allSatisfy(isDigit) else {
                throw IRIError.invalidIRIReference(authority)
            }
        }

        let literal = hostPort[(hostPort.startIndex + 1)..<closingBracket]
        guard isValidIPv6Address(literal) || isValidIPvFuture(literal) else {
            throw IRIError.invalidIRIReference(authority)
        }
    }

    /// Checks `IPv4address / ireg-name` (RFC 3987 section 2.2). As RFC 3986
    /// section 3.2.2 says, a host that matches `IPv4address` is an IPv4
    /// literal; any other host is a registered name, so text such as
    /// `1.2.3`, `999.1.1.1` or `127.0.0.01` is a valid `ireg-name`.
    private static func validateRegisteredOrIPv4Host(_ host: Scalars, authority: String) throws {
        if isValidIPv4Address(host) {
            return
        }

        try validatePercentEncoding(in: text(host))
        guard host.allSatisfy({ scalar in
            isIUnreserved(scalar) || isSubDelimiter(scalar) || scalar == "%"
        }) else {
            throw IRIError.invalidIRIReference(authority)
        }
    }

    private static func isValidIPvFuture(_ literal: Scalars) -> Bool {
        // RFC 5234 section 2.3: the ABNF literal "v" matches "v" or "V".
        guard literal.first == "v" || literal.first == "V" else {
            return false
        }

        guard let dotIndex = literal.firstIndex(of: ".") else {
            return false
        }

        let version = literal[(literal.startIndex + 1)..<dotIndex]
        let address = literal[(dotIndex + 1)...]

        guard !version.isEmpty,
            !address.isEmpty,
            version.allSatisfy(isHexDigit)
        else {
            return false
        }

        return address.allSatisfy {
            isUnreserved($0) || isSubDelimiter($0) || $0 == ":"
        }
    }

    private static func isValidIPv6Address(_ literal: Scalars) -> Bool {
        guard !literal.isEmpty,
            !literal.contains("%")
        else {
            return false
        }

        let doubleColonCount = literal.indices.filter {
            literal[$0] == ":" && $0 + 1 < literal.endIndex && literal[$0 + 1] == ":"
        }.count
        guard doubleColonCount <= 1 else {
            return false
        }

        let addressPart: Scalars
        let ipv4GroupCount: Int
        if literal.contains(".") {
            guard let lastColon = literal.lastIndex(of: ":") else {
                return false
            }

            guard isValidIPv4Address(literal[(lastColon + 1)...]) else {
                return false
            }

            if lastColon > literal.startIndex, literal[lastColon - 1] == ":" {
                addressPart = literal[...lastColon]
            } else {
                addressPart = literal[..<lastColon]
            }
            ipv4GroupCount = 2
        } else {
            addressPart = literal
            ipv4GroupCount = 0
        }

        if let compression = addressPart.indices.first(where: {
            addressPart[$0] == ":" && $0 + 1 < addressPart.endIndex && addressPart[$0 + 1] == ":"
        }) {
            guard let leftGroups = h16Groups(addressPart[..<compression]),
                let rightGroups = h16Groups(addressPart[(compression + 2)...])
            else {
                return false
            }

            return leftGroups + rightGroups + ipv4GroupCount < 8
        }

        guard let groups = h16Groups(addressPart) else {
            return false
        }

        return groups + ipv4GroupCount == 8
    }

    /// Counts the `h16` groups of a colon-separated run, or returns `nil`
    /// when a group is not one to four hexadecimal digits.
    private static func h16Groups(_ scalars: Scalars) -> Int? {
        guard !scalars.isEmpty else {
            return 0
        }

        let groups = scalars.split(separator: ":", omittingEmptySubsequences: false)
        guard groups.allSatisfy({ group in
            !group.isEmpty
                && group.count <= 4
                && group.allSatisfy(isHexDigit)
        }) else {
            return nil
        }

        return groups.count
    }

    /// Checks the `IPv4address` rule of RFC 3986 section 3.2.2: four
    /// `dec-octet` values from 0 to 255, without leading zeros.
    private static func isValidIPv4Address(_ host: Scalars) -> Bool {
        let pieces = host.split(separator: ".", omittingEmptySubsequences: false)
        guard pieces.count == 4 else {
            return false
        }

        return pieces.allSatisfy { piece in
            guard !piece.isEmpty,
                piece.count <= 3,
                piece.allSatisfy(isDigit),
                piece.count == 1 || piece.first != "0"
            else {
                return false
            }

            let value = piece.reduce(0) { $0 * 10 + Int($1.value - 0x30) }
            return value <= 255
        }
    }

    private static func isValidScheme(_ scheme: Scalars) -> Bool {
        guard let first = scheme.first, isAlpha(first) else {
            return false
        }

        return scheme.dropFirst().allSatisfy {
            isAlpha($0) || isDigit($0) || $0 == "+" || $0 == "-" || $0 == "."
        }
    }

    private static func isAllowed(
        _ scalar: Unicode.Scalar,
        allowsPrivate: Bool,
        allowsFragment: Bool
    ) -> Bool {
        guard !isBidiFormattingCharacter(scalar) else {
            return false
        }

        return isIUnreserved(scalar)
            || isReserved(scalar)
            || scalar == "%"
            || (allowsPrivate && isIPrivate(scalar))
            || (allowsFragment && scalar == "#")
    }

    /// The characters an `ipath` may hold: `ipchar` and `/`.
    static func isPathCharacter(_ scalar: Unicode.Scalar) -> Bool {
        isIUnreserved(scalar)
            || isSubDelimiter(scalar)
            || scalar == "%"
            || scalar == ":"
            || scalar == "@"
            || scalar == "/"
    }

    static func isIUnreserved(_ scalar: Unicode.Scalar) -> Bool {
        isUnreserved(scalar) || isUCSChar(scalar)
    }

    private static func isUnreserved(_ scalar: Unicode.Scalar) -> Bool {
        isAlpha(scalar) || isDigit(scalar) || scalar == "-" || scalar == "." || scalar == "_"
            || scalar == "~"
    }

    private static func isReserved(_ scalar: Unicode.Scalar) -> Bool {
        ":/?[]@!$&'()*+,;=".unicodeScalars.contains(scalar)
    }

    static func isSubDelimiter(_ scalar: Unicode.Scalar) -> Bool {
        "!$&'()*+,;=".unicodeScalars.contains(scalar)
    }

    static func isUCSChar(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0xA0...0xD7FF,
            0xF900...0xFDCF,
            0xFDF0...0xFFEF,
            0x10000...0x1FFFD,
            0x20000...0x2FFFD,
            0x30000...0x3FFFD,
            0x40000...0x4FFFD,
            0x50000...0x5FFFD,
            0x60000...0x6FFFD,
            0x70000...0x7FFFD,
            0x80000...0x8FFFD,
            0x90000...0x9FFFD,
            0xA0000...0xAFFFD,
            0xB0000...0xBFFFD,
            0xC0000...0xCFFFD,
            0xD0000...0xDFFFD,
            0xE1000...0xEFFFD:
            true
        default:
            false
        }
    }

    static func isIPrivate(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0xE000...0xF8FF,
            0xF0000...0xFFFFD,
            0x100000...0x10FFFD:
            true
        default:
            false
        }
    }

    static func isBidiFormattingCharacter(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x200E...0x200F,
            0x202A...0x202E:
            true
        default:
            false
        }
    }

    private static func isAlpha(_ scalar: Unicode.Scalar) -> Bool {
        (0x41...0x5A).contains(scalar.value) || (0x61...0x7A).contains(scalar.value)
    }

    static func isDigit(_ scalar: Unicode.Scalar) -> Bool {
        (0x30...0x39).contains(scalar.value)
    }

    static func isHexDigit(_ scalar: Unicode.Scalar) -> Bool {
        isDigit(scalar) || (0x41...0x46).contains(scalar.value) || (0x61...0x66).contains(scalar.value)
    }
}
