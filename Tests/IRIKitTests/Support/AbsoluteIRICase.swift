struct AbsoluteIRICase: Sendable {
    let iri: String
    let scheme: String
    let authority: String?
    let path: String
    let query: String?
    let fragment: String?
}
