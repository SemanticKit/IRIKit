import IRIKit
import Testing

@Suite("AbsoluteIRI ExpressibleByStringLiteral coverage")
struct AbsoluteIRIExpressibleByStringLiteralTests {
    @Test("AbsoluteIRI ExpressibleByStringLiteral should validate static absolute IRI literals.")
    func createsAbsoluteIRIFromStringLiteral() {
        let iri: AbsoluteIRI = "https://example.com/people/renée"

        requireExpressibleByStringLiteral(AbsoluteIRI.self)
        #expect(iri.rawValue == "https://example.com/people/renée")
    }
}
