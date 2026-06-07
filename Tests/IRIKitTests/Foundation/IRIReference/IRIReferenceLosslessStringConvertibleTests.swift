import IRIKit
import Testing

@Suite("IRIReference LosslessStringConvertible coverage")
struct IRIReferenceLosslessStringConvertibleTests {
    @Test("IRIReference LosslessStringConvertible should recreate a validated reference from its description.")
    func recreatesReferenceFromDescription() {
        let description = "../people/renée?view=summary#details"
        let reference = IRIReference(description)

        requireLosslessStringConvertible(IRIReference.self)
        #expect(reference?.rawValue == "../people/renée?view=summary#details")
        #expect(reference?.description == "../people/renée?view=summary#details")
    }

    @Test("IRIReference LosslessStringConvertible should reject strings that are not IRI references.")
    func rejectsInvalidDescription() {
        let description = "https://example.com/%ZZ"

        #expect(IRIReference(description) == nil)
    }
}
