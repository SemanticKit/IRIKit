import IRIKit
import Testing

@Suite("IRIComponents Hashable coverage")
struct IRIComponentsHashableTests {
    @Test("IRIComponents provides Hashable with equal components collapsing to one set member.")
    func collapsesEqualValuesInASet() {
        let value = IRIComponents(scheme: "https", authority: "example.com")
        let values: Set = [value, value]

        requireHashable(IRIComponents.self)
        #expect(values.count == 1)
    }

    @Test("IRIComponents hashes by Unicode scalars, so precomposed and decomposed 'é' stay separate set members.")
    func keepsDistinctScalarSequencesApart() {
        let precomposed = IRIComponents(scheme: "https", authority: "example.com", path: "/ren\u{E9}e")
        let decomposed = IRIComponents(scheme: "https", authority: "example.com", path: "/rene\u{301}e")
        let values: Set = [precomposed, decomposed]

        #expect(values.count == 2)
    }

    @Test("Equal IRIComponents have equal hash values.")
    func hashesEqualValuesEqually() {
        let lhs = IRIComponents(scheme: "urn", path: "a", query: "", fragment: "f")
        let rhs = IRIComponents(scheme: "urn", path: "a", query: "", fragment: "f")

        #expect(lhs.hashValue == rhs.hashValue)
    }
}
