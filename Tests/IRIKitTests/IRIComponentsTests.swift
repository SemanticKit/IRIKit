import IRIKit
import Testing

@Suite("IRI components")
struct IRIComponentsTests {
    @Test func buildsAbsoluteIRIFromStructuredComponents() throws {
        let components = IRIComponents(
            scheme: "https",
            authority: "example.com",
            path: "/people/renée",
            query: "view=summary",
            fragment: "details"
        )

        let iri = try components.iri()

        #expect(components.string == "https://example.com/people/renée?view=summary#details")
        #expect(iri.rawValue == components.string)
        #expect(iri.scheme == "https")
        #expect(iri.authority == "example.com")
        #expect(iri.path == "/people/renée")
        #expect(iri.query == "view=summary")
        #expect(iri.fragment == "details")
    }

    @Test func reportsInvalidComponentAssemblyThroughIRIValidation() {
        let components = IRIComponents(
            scheme: "1https",
            authority: "example.com",
            path: "/people"
        )

        #expect(throws: IRIError.invalidIRI("1https://example.com/people")) {
            try components.iri()
        }
    }
}
