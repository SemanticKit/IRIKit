enum IRITemplateParser {
    static func validate(_ template: String) throws {
        var index = template.startIndex
        while index < template.endIndex {
            switch template[index] {
            case "{":
                let close = try closingBrace(in: template, from: index)
                let name = template[template.index(after: index)..<close]
                guard !name.isEmpty, name.allSatisfy(isTemplateNameCharacter) else {
                    throw IRIError.invalidTemplate(template)
                }
                index = template.index(after: close)
            case "}":
                throw IRIError.invalidTemplate(template)
            default:
                index = template.index(after: index)
            }
        }
    }

    static func expand(_ template: String, values: [String: String]) throws -> String {
        try validate(template)

        var result = ""
        var index = template.startIndex
        while index < template.endIndex {
            guard template[index] == "{" else {
                result.append(template[index])
                index = template.index(after: index)
                continue
            }

            let close = try closingBrace(in: template, from: index)
            let name = String(template[template.index(after: index)..<close])
            guard let value = values[name] else {
                throw IRIError.missingTemplateValue(name)
            }
            result.append(value)
            index = template.index(after: close)
        }

        return result
    }

    private static func closingBrace(
        in template: String, from open: String.Index
    ) throws -> String.Index {
        let searchStart = template.index(after: open)
        guard let close = template[searchStart...].firstIndex(of: "}") else {
            throw IRIError.invalidTemplate(template)
        }
        return close
    }

    private static func isTemplateNameCharacter(_ character: Character) -> Bool {
        character == "_" || character == "-" || character.isLetter || character.isNumber
    }
}
