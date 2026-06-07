import IRIKit
import Testing

@Suite("IRIComponents LosslessStringConvertible coverage")
struct IRIComponentsLosslessStringConvertibleTests {
    @Test("IRIComponents LosslessStringConvertible should recreate components from the assembled IRI character sequence.")
    func recreatesComponentsFromDescription() {
        let components = IRIComponents("https://example.com/people/renée?view=summary#details")

        requireLosslessStringConvertible(IRIComponents.self)
        #expect(components?.scheme == "https")
        #expect(components?.authority == "example.com")
        #expect(components?.path == "/people/renée")
        #expect(components?.query == "view=summary")
        #expect(components?.fragment == "details")
    }
}
