/// A template that expands into an absolute IRI.
///
/// `IRITemplate` is the IRI counterpart to URL template-style construction. It
/// preserves literal IRI text and replaces `{name}` placeholders with supplied
/// values before validating the expanded result as an `IRI`.
public struct IRITemplate: ExpressibleByStringLiteral, LosslessStringConvertible, RawRepresentable {
    /// The original template text.
    public let rawValue: String

    /// Creates an IRI template by validating template syntax.
    ///
    /// - Parameter rawValue: Template text containing literal IRI characters
    ///   and optional `{name}` placeholders.
    /// - Throws: `IRIError.invalidTemplate` when braces are unmatched or a
    ///   placeholder name is empty.
    public init(validating rawValue: String) throws {
        try IRITemplateParser.validate(rawValue)
        self.rawValue = rawValue
    }

    /// Creates an IRI template from a raw value.
    ///
    /// This initializer returns `nil` when the template syntax is invalid.
    public init?(rawValue: String) {
        try? self.init(validating: rawValue)
    }

    /// Creates an IRI template from a lossless string description.
    ///
    /// This initializer returns `nil` when the template syntax is invalid.
    public init?(_ description: String) {
        try? self.init(validating: description)
    }

    /// Creates an IRI template from a string literal.
    ///
    /// Invalid literals fail validation at runtime.
    public init(stringLiteral value: String) {
        self = try! Self(validating: value)
    }

    /// Expands the template with string values and validates the result.
    ///
    /// Template values are inserted as IRI characters and percent-escaped only
    /// when the corresponding URI form requires it.
    ///
    /// - Parameter values: Values keyed by placeholder name.
    /// - Returns: The expanded absolute IRI.
    /// - Throws: `IRIError.missingTemplateValue` for a missing placeholder or
    ///   `IRIError.invalidIRI` when expansion does not produce an absolute IRI.
    public func expand(_ values: [String: String]) throws -> IRI {
        try IRI(validating: try IRITemplateParser.expand(rawValue, values: values))
    }
}

extension IRITemplate: Codable {}

extension IRITemplate: CustomDebugStringConvertible {
    /// A debug description of the original IRI template text.
    public var debugDescription: String {
        rawValue
    }
}

extension IRITemplate: Hashable {
    /// Hashes the original Unicode scalar sequence.
    public func hash(into hasher: inout Hasher) {
        for scalar in rawValue.unicodeScalars {
            hasher.combine(scalar.value)
        }
    }
}

extension IRITemplate: Sendable {}
