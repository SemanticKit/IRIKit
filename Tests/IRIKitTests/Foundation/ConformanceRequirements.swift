func requireCodable<T: Decodable & Encodable>(_ type: T.Type) {}

func requireComparable<T: Comparable>(_ type: T.Type) {}

func requireCustomStringConvertible<T: CustomStringConvertible>(_ type: T.Type) {}

func requireEquatable<T: Equatable>(_ type: T.Type) {}

func requireExpressibleByStringLiteral<T: ExpressibleByStringLiteral>(_ type: T.Type) {}

func requireHashable<T: Hashable>(_ type: T.Type) {}

func requireLosslessStringConvertible<T: LosslessStringConvertible>(_ type: T.Type) {}

func requireRawRepresentable<T: RawRepresentable>(_ type: T.Type) {}

func requireSendable<T: Sendable>(_ type: T.Type) {}

