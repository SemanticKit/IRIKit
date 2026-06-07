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
}

