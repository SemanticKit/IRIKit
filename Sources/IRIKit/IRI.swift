/// An Internationalized Resource Identifier.
///
/// `IRI` stores an absolute RFC 3987 identifier as a Unicode character
/// sequence. The original string is the identity token; equality, hashing, and
/// ordering use simple string comparison.
public struct IRI: ExpressibleByStringLiteral, LosslessStringConvertible, RawRepresentable {
    /// The original IRI character sequence.
    public let rawValue: String

    /// The IRI scheme.
    public let scheme: String

    /// The authority component, when the IRI uses `//`.
    public let authority: String?

    /// The path component.
    public let path: String

    /// The query component without the leading question mark.
    public let query: String?

    /// The fragment component without the leading number sign.
    public let fragment: String?

    /// Creates an absolute IRI by validating a Unicode character sequence.
    ///
    /// - Parameter string: The RFC 3987 IRI character sequence.
    /// - Throws: `IRIError.invalidIRI` when the string is not an absolute IRI.
    public init(validating string: String) throws {
        let parsed = try IRIParser.parseIRI(string)
        self.rawValue = string
        self.scheme = parsed.scheme
        self.authority = parsed.authority
        self.path = parsed.path
        self.query = parsed.query
        self.fragment = parsed.fragment
    }

    /// Creates an absolute IRI from components.
    ///
    /// - Parameter components: Component values that assemble into an absolute
    ///   RFC 3987 IRI.
    /// - Throws: `IRIError.invalidIRI` when the assembled character sequence
    ///   is not an absolute IRI.
    public init(components: IRIComponents) throws {
        try self.init(validating: components.string)
    }

    /// Creates an absolute IRI from a raw value.
    ///
    /// This initializer returns `nil` when the string is not an absolute IRI.
    public init?(rawValue: String) {
        try? self.init(validating: rawValue)
    }

    /// Creates an absolute IRI from a lossless string description.
    ///
    /// This initializer returns `nil` when the description is not an absolute
    /// IRI.
    public init?(_ description: String) {
        try? self.init(validating: description)
    }

    /// Creates an absolute IRI from a string.
    ///
    /// This initializer returns `nil` when the string is not an absolute IRI.
    public init?(string: String) {
        try? self.init(validating: string)
    }

    /// Creates an absolute IRI from a string literal.
    ///
    /// Invalid literals fail validation at runtime.
    public init(stringLiteral value: String) {
        self = try! Self(validating: value)
    }
}

extension IRI: Codable {}

extension IRI: Comparable {
    /// Returns whether the left IRI sorts before the right IRI by simple
    /// string comparison.
    public static func < (lhs: IRI, rhs: IRI) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension IRI: Equatable {
    /// Returns whether two IRIs contain the same Unicode scalar sequence.
    public static func == (lhs: IRI, rhs: IRI) -> Bool {
        lhs.rawValue.unicodeScalars.elementsEqual(rhs.rawValue.unicodeScalars)
    }
}

extension IRI: CustomStringConvertible {
    /// The original IRI character sequence.
    public var description: String {
        rawValue
    }
}

extension IRI: CustomDebugStringConvertible {
    /// A debug description of the original IRI character sequence.
    public var debugDescription: String {
        rawValue
    }
}

extension IRI: Hashable {
    /// Hashes the original Unicode scalar sequence.
    public func hash(into hasher: inout Hasher) {
        for scalar in rawValue.unicodeScalars {
            hasher.combine(scalar.value)
        }
    }
}

extension IRI: Sendable {}
