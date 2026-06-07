struct ParsedIRIComponents {
    let scheme: String
    let authority: String?
    let path: String
    let query: String?
    let fragment: String?
}

extension ParsedIRIComponents: Equatable {}

extension ParsedIRIComponents: Sendable {}
