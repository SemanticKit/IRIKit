import IRIKit
import Testing

@Suite("IRI ExpressibleByStringLiteral coverage")
struct IRIExpressibleByStringLiteralTests {
    @Test("IRI ExpressibleByStringLiteral should validate static IRI literals.")
    func createsIRIFromStringLiteral() {
        let iri: IRI = "https://example.com/people/renée"

        requireExpressibleByStringLiteral(IRI.self)
        #expect(iri.rawValue == "https://example.com/people/renée")
    }
}
