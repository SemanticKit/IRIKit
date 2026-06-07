import IRIKit
import Testing

@Suite("IRIComponents Equatable coverage")
struct IRIComponentsEquatableTests {
    @Test("IRIComponents provides Equatable by comparing each component value.")
    func comparesEachComponent() {
        let lhs = IRIComponents(
            scheme: "https",
            authority: "example.com",
            path: "/people/renée",
            query: "view=summary",
            fragment: "details"
        )
        let rhs = IRIComponents(
            scheme: "https",
            authority: "example.com",
            path: "/people/renée",
            query: "view=summary",
            fragment: "details"
        )

        requireEquatable(IRIComponents.self)
        #expect(lhs == rhs)
    }
}
