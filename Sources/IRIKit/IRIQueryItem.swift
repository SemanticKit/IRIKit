/// A single name-value pair for constructing an IRI query component.
///
/// `IRIQueryItem` assembles query text using the conventional `name=value`
/// shape without applying percent-encoding. The resulting query remains subject
/// to RFC 3987 validation when the surrounding ``IRIComponents`` value creates
/// an ``IRI``.
public struct IRIQueryItem {
    /// The query item name.
    public var name: String

    /// The query item value.
    ///
    /// A `nil` value assembles as the name alone. An empty string assembles as
    /// the name followed by `=`.
    public var value: String?

    /// Creates a query item from a name and optional value.
    ///
    /// - Parameters:
    ///   - name: The query item name.
    ///   - value: The query item value, or `nil` when the item has no value.
    public init(name: String, value: String? = nil) {
        self.name = name
        self.value = value
    }

    /// The assembled query item character sequence.
    public var string: String {
        guard let value else {
            return name
        }

        return "\(name)=\(value)"
    }

    /// The assembled query item character sequence.
    public var description: String {
        string
    }
}

extension IRIQueryItem: Codable {}

extension IRIQueryItem: Equatable {}

extension IRIQueryItem: Hashable {}

extension IRIQueryItem: Sendable {}

extension IRIQueryItem: CustomStringConvertible {}
