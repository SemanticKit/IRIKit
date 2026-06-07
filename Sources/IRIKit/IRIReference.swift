/// An absolute or relative Internationalized Resource Identifier reference.
///
/// `IRIReference` follows RFC 3987's distinction between IRI references and
/// absolute IRIs. A reference may be relative; resolving it to an absolute IRI
/// is a separate operation owned by the caller's context.
public struct IRIReference: ExpressibleByStringLiteral, LosslessStringConvertible, RawRepresentable {
    /// The original IRI reference character sequence.
    public let rawValue: String

    /// Creates an IRI reference by validating a Unicode character sequence.
    ///
    /// - Parameter string: The RFC 3987 IRI reference character sequence.
    /// - Throws: `IRIError.invalidIRIReference` when the string is not an IRI
    ///   reference.
    public init(validating string: String) throws {
        _ = try IRIParser.parseIRIReference(string)
        self.rawValue = string
    }

    /// Creates an IRI reference from a raw value.
    ///
    /// This initializer returns `nil` when the string is not an IRI reference.
    public init?(rawValue: String) {
        try? self.init(validating: rawValue)
    }

    /// Creates an IRI reference from a lossless string description.
    ///
    /// This initializer returns `nil` when the description is not an IRI
    /// reference.
    public init?(_ description: String) {
        try? self.init(validating: description)
    }

    /// Creates an IRI reference from a string literal.
    ///
    /// Invalid literals fail validation at runtime.
    public init(stringLiteral value: String) {
        self = try! Self(validating: value)
    }
}

extension IRIReference: Codable {}

extension IRIReference: Comparable {
    /// Returns whether the left reference sorts before the right reference by
    /// simple string comparison.
    public static func < (lhs: IRIReference, rhs: IRIReference) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension IRIReference: Equatable {
    /// Returns whether two references contain the same Unicode scalar sequence.
    public static func == (lhs: IRIReference, rhs: IRIReference) -> Bool {
        lhs.rawValue.unicodeScalars.elementsEqual(rhs.rawValue.unicodeScalars)
    }
}

extension IRIReference: CustomStringConvertible {
    /// The original IRI reference character sequence.
    public var description: String {
        rawValue
    }
}

extension IRIReference: CustomDebugStringConvertible {
    /// A debug description of the original IRI reference character sequence.
    public var debugDescription: String {
        rawValue
    }
}

extension IRIReference: Hashable {
    /// Hashes the original Unicode scalar sequence.
    public func hash(into hasher: inout Hasher) {
        for scalar in rawValue.unicodeScalars {
            hasher.combine(scalar.value)
        }
    }
}

extension IRIReference: Sendable {}
