import IRIKit
import Testing

@Suite("IRIReference Hashable coverage")
struct IRIReferenceHashableTests {
    @Test("IRIReference provides Hashable with equal references collapsing to one set member.")
    func collapsesEqualValuesInASet() throws {
        let values: Set = [
            try IRIReference(validating: "../a"),
            try IRIReference(validating: "../a"),
            try IRIReference(validating: "../b"),
        ]

        requireHashable(IRIReference.self)
        #expect(values.count == 2)
    }
}
