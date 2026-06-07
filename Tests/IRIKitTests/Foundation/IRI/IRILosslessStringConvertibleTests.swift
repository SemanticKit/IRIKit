import IRIKit
import Testing

@Suite("IRI LosslessStringConvertible coverage")
struct IRILosslessStringConvertibleTests {
    @Test("IRI LosslessStringConvertible should recreate a validated IRI from its description.")
    func recreatesIRIFromDescription() {
        let description = "https://example.com/people/renée?view=summary#details"
        let iri = IRI(description)

        requireLosslessStringConvertible(IRI.self)
        #expect(iri?.rawValue == "https://example.com/people/renée?view=summary#details")
        #expect(iri?.description == "https://example.com/people/renée?view=summary#details")
    }

    @Test("IRI LosslessStringConvertible should reject strings that are not absolute IRIs.")
    func rejectsInvalidDescription() {
        let description = "1https://example.com"

        #expect(IRI(description) == nil)
    }
}
