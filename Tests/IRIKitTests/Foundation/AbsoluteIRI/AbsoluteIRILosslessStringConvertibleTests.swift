import IRIKit
import Testing

@Suite("AbsoluteIRI LosslessStringConvertible coverage")
struct AbsoluteIRILosslessStringConvertibleTests {
    @Test("AbsoluteIRI LosslessStringConvertible should recreate a validated absolute IRI from its description.")
    func recreatesAbsoluteIRIFromDescription() {
        let description = "https://example.com/people/renée?view=summary"
        let iri = AbsoluteIRI(description)

        requireLosslessStringConvertible(AbsoluteIRI.self)
        #expect(iri?.rawValue == "https://example.com/people/renée?view=summary")
        #expect(iri?.description == "https://example.com/people/renée?view=summary")
    }

    @Test("AbsoluteIRI LosslessStringConvertible should reject descriptions with fragments.")
    func rejectsFragmentDescription() {
        let description = "https://example.com/people/renée#details"

        #expect(AbsoluteIRI(description) == nil)
    }
}
