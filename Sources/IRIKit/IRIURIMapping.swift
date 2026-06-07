enum IRIURIMapping {
    static func uriString(from iriString: String) -> String {
        var result = ""
        for scalar in iriString.unicodeScalars {
            if isURICharacter(scalar) {
                result.unicodeScalars.append(scalar)
            } else {
                for byte in String(scalar).utf8 {
                    result.append("%")
                    result.append(hexDigit(byte >> 4))
                    result.append(hexDigit(byte & 0x0F))
                }
            }
        }
        return result
    }

    static func iriString(fromURIString uriString: String) -> String {
        var result = ""
        var index = uriString.startIndex
        while index < uriString.endIndex {
            guard uriString[index] == "%" else {
                result.append(uriString[index])
                index = uriString.index(after: index)
                continue
            }

            let start = index
            var bytes: [UInt8] = []
            while index < uriString.endIndex,
                uriString[index] == "%",
                let byte = percentEncodedByte(in: uriString, at: index)
            {
                bytes.append(byte)
                index = uriString.index(index, offsetBy: 3)
            }

            if let decoded = decodedIRICharacters(from: bytes) {
                result.append(decoded)
            } else {
                result.append(String(uriString[start..<index]))
            }
        }
        return result
    }

    private static func isURICharacter(_ scalar: Unicode.Scalar) -> Bool {
        isAlpha(scalar)
            || isDigit(scalar)
            || "-._~:/?#[]@!$&'()*+,;=%".unicodeScalars.contains(scalar)
    }

    private static func percentEncodedByte(in string: String, at percentIndex: String.Index) -> UInt8? {
        let firstIndex = string.index(after: percentIndex)
        guard firstIndex < string.endIndex else {
            return nil
        }

        let secondIndex = string.index(after: firstIndex)
        guard secondIndex < string.endIndex,
            let high = hexValue(string[firstIndex]),
            let low = hexValue(string[secondIndex])
        else {
            return nil
        }

        return high << 4 | low
    }

    private static func decodedIRICharacters(from bytes: [UInt8]) -> String? {
        var decoder = Unicode.UTF8()
        var iterator = bytes.makeIterator()
        var result = ""

        while true {
            switch decoder.decode(&iterator) {
            case .scalarValue(let scalar):
                guard shouldDecodePercentEncodedScalar(scalar) else {
                    return nil
                }
                result.unicodeScalars.append(scalar)
            case .emptyInput:
                return result.isEmpty ? nil : result
            case .error:
                return nil
            }
        }
    }

    private static func shouldDecodePercentEncodedScalar(_ scalar: Unicode.Scalar) -> Bool {
        scalar.value >= 0x80
            && !isBidiFormattingCharacter(scalar)
            && !isIPrivate(scalar)
    }

    private static func hexValue(_ character: Character) -> UInt8? {
        guard let scalar = character.unicodeScalars.first,
            character.unicodeScalars.count == 1
        else {
            return nil
        }

        switch scalar.value {
        case 0x30...0x39:
            return UInt8(scalar.value - 0x30)
        case 0x41...0x46:
            return UInt8(scalar.value - 0x41 + 10)
        case 0x61...0x66:
            return UInt8(scalar.value - 0x61 + 10)
        default:
            return nil
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

    private static func hexDigit(_ value: UInt8) -> Character {
        Character(String(value, radix: 16, uppercase: true))
    }

    private static func isAlpha(_ scalar: Unicode.Scalar) -> Bool {
        (0x41...0x5A).contains(scalar.value) || (0x61...0x7A).contains(scalar.value)
    }

    private static func isDigit(_ scalar: Unicode.Scalar) -> Bool {
        (0x30...0x39).contains(scalar.value)
    }
}
