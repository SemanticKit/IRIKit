/// An absolute IRI without a fragment component.
///
/// `AbsoluteIRI` represents RFC 3987's `absolute-IRI` production. It has the
/// same component shape as `IRI` except that fragments are rejected.
public struct AbsoluteIRI: ExpressibleByStringLiteral, LosslessStringConvertible, RawRepresentable {
    /// The original absolute IRI character sequence.
    public let rawValue: String

    /// The IRI scheme.
    public let scheme: String

    /// The authority component, when the IRI uses `//`.
    public let authority: String?

    /// The path component.
    public let path: String

    /// The query component without the leading question mark.
    public let query: String?

    /// Creates an absolute IRI without a fragment.
    ///
    /// - Parameter string: The RFC 3987 absolute-IRI character sequence.
    /// - Throws: `IRIError.invalidIRI` when the string is not an absolute IRI
    ///   or contains a fragment.
    public init(validating string: String) throws {
        let iri = try IRI(validating: string)
        guard iri.fragment == nil else {
            throw IRIError.invalidIRI(string)
        }

        self.rawValue = string
        self.scheme = iri.scheme
        self.authority = iri.authority
        self.path = iri.path
        self.query = iri.query
    }

    /// Creates an absolute IRI from a raw value.
    ///
    /// This initializer returns `nil` when the string is not an absolute IRI
    /// or contains a fragment.
    public init?(rawValue: String) {
        try? self.init(validating: rawValue)
    }

    /// Creates an absolute IRI from a lossless string description.
    ///
    /// This initializer returns `nil` when the description is not an absolute
    /// IRI or contains a fragment.
    public init?(_ description: String) {
        try? self.init(validating: description)
    }

    /// Creates an absolute IRI from a string literal.
    ///
    /// Invalid literals fail validation at runtime.
    public init(stringLiteral value: String) {
        self = try! Self(validating: value)
    }
}

extension AbsoluteIRI: Codable {}

extension AbsoluteIRI: Comparable {
    /// Returns whether the left absolute IRI sorts before the right absolute
    /// IRI by simple string comparison.
    public static func < (lhs: AbsoluteIRI, rhs: AbsoluteIRI) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension AbsoluteIRI: Equatable {
    /// Returns whether two absolute IRIs contain the same Unicode scalar
    /// sequence.
    public static func == (lhs: AbsoluteIRI, rhs: AbsoluteIRI) -> Bool {
        lhs.rawValue.unicodeScalars.elementsEqual(rhs.rawValue.unicodeScalars)
    }
}

extension AbsoluteIRI: CustomStringConvertible {
    /// The original absolute IRI character sequence.
    public var description: String {
        rawValue
    }
}

extension AbsoluteIRI: CustomDebugStringConvertible {
    /// A debug description of the original absolute IRI character sequence.
    public var debugDescription: String {
        rawValue
    }
}

extension AbsoluteIRI: Hashable {
    /// Hashes the original Unicode scalar sequence.
    public func hash(into hasher: inout Hasher) {
        for scalar in rawValue.unicodeScalars {
            hasher.combine(scalar.value)
        }
    }
}

extension AbsoluteIRI: Sendable {}
