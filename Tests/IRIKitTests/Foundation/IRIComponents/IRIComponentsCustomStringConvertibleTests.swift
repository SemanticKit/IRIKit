import IRIKit
import Testing

@Suite("IRIComponents CustomStringConvertible coverage")
struct IRIComponentsCustomStringConvertibleTests {
    @Test("IRIComponents CustomStringConvertible should describe the assembled IRI character sequence.")
    func describesAssembledIRI() {
        let components = IRIComponents(
            scheme: "https",
            authority: "example.com",
            path: "/people/renée",
            query: "view=summary",
            fragment: "details"
        )

        requireCustomStringConvertible(IRIComponents.self)
        #expect(components.description == "https://example.com/people/renée?view=summary#details")
    }
}
