enum IRIParser {
    static func parseIRI(_ string: String) throws -> ParsedIRIComponents {
        guard let schemeEnd = string.firstIndex(of: ":") else {
            throw IRIError.invalidIRI(string)
        }

        let scheme = String(string[..<schemeEnd])
        guard isValidScheme(scheme) else {
            throw IRIError.invalidIRI(string)
        }

        let rest = string[string.index(after: schemeEnd)...]
        do {
            let components = try parseHierPart(rest, scheme: scheme)
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
        if string.firstIndex(of: ":").map({ isValidScheme(String(string[..<$0])) }) == true {
            _ = try parseIRI(string)
        }
    }

    private static func parseHierPart(
        _ rest: Substring, scheme: String
    ) throws -> ParsedIRIComponents {
        var remaining = rest
        var authority: String?

        if remaining.hasPrefix("//") {
            remaining.removeFirst(2)
            let authorityEnd =
                remaining.firstIndex { $0 == "/" || $0 == "?" || $0 == "#" } ?? remaining.endIndex
            let authorityValue = String(remaining[..<authorityEnd])
            guard !authorityValue.isEmpty else {
                throw IRIError.invalidIRIReference(String(rest))
            }
            authority = authorityValue
            remaining = remaining[authorityEnd...]
        }

        let fragmentSplit = split(remaining, at: "#")
        let querySplit = split(fragmentSplit.head, at: "?")
        let path = String(querySplit.head)

        if authority == nil, path.hasPrefix("//") {
            throw IRIError.invalidIRIReference(String(rest))
        }

        return ParsedIRIComponents(
            scheme: scheme,
            authority: authority,
            path: path,
            query: querySplit.tail,
            fragment: fragmentSplit.tail
        )
    }

    private static func split(
        _ input: Substring, at separator: Character
    ) -> (head: Substring, tail: String?) {
        guard let index = input.firstIndex(of: separator) else {
            return (input, nil)
        }

        return (input[..<index], String(input[input.index(after: index)...]))
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

    private static func validatePercentEncoding(in string: String) throws {
        var index = string.startIndex
        while index < string.endIndex {
            guard string[index] == "%" else {
                index = string.index(after: index)
                continue
            }

            let first = string.index(after: index)
            guard first < string.endIndex else {
                throw IRIError.invalidIRIReference(string)
            }

            let second = string.index(after: first)
            guard second < string.endIndex,
                string[first].isHexDigit,
                string[second].isHexDigit
            else {
                throw IRIError.invalidIRIReference(string)
            }

            index = string.index(after: second)
        }
    }

    private static func validatePathCharacters(in path: String) throws {
        try validateCharacters(in: path, allowsPrivate: false)

        guard path.unicodeScalars.allSatisfy({ scalar in
            isIUnreserved(scalar)
                || isSubDelimiter(scalar)
                || scalar == "%"
                || scalar == ":"
                || scalar == "@"
                || scalar == "/"
        }) else {
            throw IRIError.invalidIRIReference(path)
        }
    }

    private static func validateAuthority(_ authority: String?) throws {
        guard let authority else {
            return
        }

        let authorityPieces = authority.split(
            separator: "@",
            omittingEmptySubsequences: false
        )
        guard authorityPieces.count <= 2 else {
            throw IRIError.invalidIRIReference(authority)
        }

        let hostPort = String(authorityPieces.last ?? "")
        if hostPort.hasPrefix("[") {
            try validateIPLiteralHostPort(hostPort, authority: authority)
            return
        }

        guard !hostPort.contains("["),
            !hostPort.contains("]")
        else {
            throw IRIError.invalidIRIReference(authority)
        }

        let pieces = hostPort.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        let host = String(pieces[0])
        try validateRegisteredOrIPv4Host(host, authority: authority)

        guard pieces.count == 2 else {
            return
        }

        guard pieces[1].allSatisfy({ $0.isNumber }) else {
            throw IRIError.invalidIRIReference(authority)
        }
    }

    private static func validateIPLiteralHostPort(_ hostPort: String, authority: String) throws {
        guard let closingBracket = hostPort.firstIndex(of: "]") else {
            throw IRIError.invalidIRIReference(authority)
        }

        let afterBracket = hostPort.index(after: closingBracket)
        guard afterBracket == hostPort.endIndex || hostPort[afterBracket] == ":" else {
            throw IRIError.invalidIRIReference(authority)
        }

        if afterBracket < hostPort.endIndex {
            let portStart = hostPort.index(after: afterBracket)
            guard hostPort[portStart...].allSatisfy({ $0.isNumber }) else {
                throw IRIError.invalidIRIReference(authority)
            }
        }

        let literalStart = hostPort.index(after: hostPort.startIndex)
        let literal = String(hostPort[literalStart..<closingBracket])
        guard isValidIPv6Address(literal) || isValidIPvFuture(literal) else {
            throw IRIError.invalidIRIReference(authority)
        }
    }

    private static func validateRegisteredOrIPv4Host(_ host: String, authority: String) throws {
        if host.contains("."),
            host.allSatisfy({ $0.isNumber || $0 == "." })
        {
            guard isValidIPv4Address(host) else {
                throw IRIError.invalidIRIReference(authority)
            }
            return
        }

        try validatePercentEncoding(in: host)
        guard host.unicodeScalars.allSatisfy({ scalar in
            isIUnreserved(scalar) || isSubDelimiter(scalar) || scalar == "%"
        }) else {
            throw IRIError.invalidIRIReference(authority)
        }
    }

    private static func isValidIPvFuture(_ literal: String) -> Bool {
        guard literal.first == "v" else {
            return false
        }

        guard let dotIndex = literal.firstIndex(of: ".") else {
            return false
        }

        let versionStart = literal.index(after: literal.startIndex)
        let version = literal[versionStart..<dotIndex]
        let addressStart = literal.index(after: dotIndex)
        let address = literal[addressStart...]

        guard !version.isEmpty,
            !address.isEmpty,
            version.allSatisfy(\.isHexDigit)
        else {
            return false
        }

        return address.unicodeScalars.allSatisfy {
            isIUnreserved($0) || isSubDelimiter($0) || $0 == ":"
        }
    }

    private static func isValidIPv6Address(_ literal: String) -> Bool {
        guard !literal.isEmpty,
            !literal.contains("%")
        else {
            return false
        }

        let doubleColonCount = literal.indices.filter {
            literal[$0] == ":"
                && literal.index(after: $0) < literal.endIndex
                && literal[literal.index(after: $0)] == ":"
        }.count
        guard doubleColonCount <= 1 else {
            return false
        }

        let addressPart: String
        let ipv4GroupCount: Int
        if literal.contains(".") {
            guard let lastColon = literal.lastIndex(of: ":") else {
                return false
            }

            let ipv4Start = literal.index(after: lastColon)
            guard isValidIPv4Address(String(literal[ipv4Start...])) else {
                return false
            }

            if lastColon > literal.startIndex,
                literal[literal.index(before: lastColon)] == ":"
            {
                addressPart = String(literal[...lastColon])
            } else {
                addressPart = String(literal[..<lastColon])
            }
            ipv4GroupCount = 2
        } else {
            addressPart = literal
            ipv4GroupCount = 0
        }

        if addressPart.contains("::") {
            guard let compressionRange = addressPart.range(of: "::") else {
                return false
            }

            let left = String(addressPart[..<compressionRange.lowerBound])
            let right = String(addressPart[compressionRange.upperBound...])
            let leftGroups = h16Groups(left)
            let rightGroups = h16Groups(right)

            guard leftGroups != nil,
                rightGroups != nil
            else {
                return false
            }

            return (leftGroups?.count ?? 0) + (rightGroups?.count ?? 0) + ipv4GroupCount < 8
        }

        guard let groups = h16Groups(addressPart) else {
            return false
        }

        return groups.count + ipv4GroupCount == 8
    }

    private static func h16Groups(_ string: String) -> [Substring]? {
        guard !string.isEmpty else {
            return []
        }

        let groups = string.split(separator: ":", omittingEmptySubsequences: false)
        guard groups.allSatisfy({ group in
            !group.isEmpty
                && group.count <= 4
                && group.allSatisfy(\.isHexDigit)
        }) else {
            return nil
        }

        return groups
    }

    private static func isValidIPv4Address(_ host: String) -> Bool {
        let pieces = host.split(separator: ".", omittingEmptySubsequences: false)
        guard pieces.count == 4 else {
            return false
        }

        return pieces.allSatisfy { piece in
            guard !piece.isEmpty,
                piece.allSatisfy(\.isNumber),
                piece.count == 1 || piece.first != "0",
                let value = Int(piece)
            else {
                return false
            }

            return value <= 255
        }
    }

    private static func isValidScheme(_ scheme: String) -> Bool {
        guard let first = scheme.unicodeScalars.first, isAlpha(first) else {
            return false
        }

        return scheme.unicodeScalars.dropFirst().allSatisfy {
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

    private static func isIUnreserved(_ scalar: Unicode.Scalar) -> Bool {
        isAlpha(scalar) || isDigit(scalar) || scalar == "-" || scalar == "." || scalar == "_"
            || scalar == "~" || isUCSChar(scalar)
    }

    private static func isReserved(_ scalar: Unicode.Scalar) -> Bool {
        ":/?[]@!$&'()*+,;=".unicodeScalars.contains(scalar)
    }

    private static func isSubDelimiter(_ scalar: Unicode.Scalar) -> Bool {
        "!$&'()*+,;=".unicodeScalars.contains(scalar)
    }

    private static func isUCSChar(_ scalar: Unicode.Scalar) -> Bool {
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

    private static func isIPrivate(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0xE000...0xF8FF,
            0xF0000...0xFFFFD,
            0x100000...0x10FFFD:
            true
        default:
            false
        }
    }

    private static func isBidiFormattingCharacter(_ scalar: Unicode.Scalar) -> Bool {
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

    private static func isDigit(_ scalar: Unicode.Scalar) -> Bool {
        (0x30...0x39).contains(scalar.value)
    }
}
