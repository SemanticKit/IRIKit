import IRIKit
import Testing

@Suite("AbsoluteIRI RawRepresentable coverage")
struct AbsoluteIRIRawRepresentableTests {
    @Test("AbsoluteIRI RawRepresentable should recreate a validated absolute IRI from its raw value.")
    func recreatesAbsoluteIRIFromRawValue() {
        let iri = AbsoluteIRI(rawValue: "https://example.com/people/renée?view=summary")

        requireRawRepresentable(AbsoluteIRI.self)
        #expect(iri?.rawValue == "https://example.com/people/renée?view=summary")
    }

    @Test("AbsoluteIRI RawRepresentable should reject raw values with fragments.")
    func rejectsFragmentRawValue() {
        #expect(AbsoluteIRI(rawValue: "https://example.com/people/renée#details") == nil)
    }
}
