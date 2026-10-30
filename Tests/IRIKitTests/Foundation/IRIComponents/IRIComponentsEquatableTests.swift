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

    @Test("IRIComponents compares by Unicode scalars, as IRI does, so precomposed and decomposed 'é' are not equal.")
    func comparesUnicodeScalars() {
        let precomposed = IRIComponents(scheme: "https", authority: "example.com", path: "/ren\u{E9}e")
        let decomposed = IRIComponents(scheme: "https", authority: "example.com", path: "/rene\u{301}e")

        #expect(precomposed.path == decomposed.path)
        #expect(precomposed != decomposed)
    }
}
