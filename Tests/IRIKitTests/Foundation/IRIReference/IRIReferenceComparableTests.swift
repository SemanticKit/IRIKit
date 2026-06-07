import IRIKit
import Testing

@Suite("IRIReference Comparable coverage")
struct IRIReferenceComparableTests {
    @Test("IRIReference provides Comparable using simple string ordering.")
    func sortsBySimpleStringOrdering() throws {
        let values = [
            try IRIReference(validating: "../b"),
            try IRIReference(validating: "../a"),
        ].sorted()

        requireComparable(IRIReference.self)
        #expect(values.map(\.rawValue) == [
            "../a",
            "../b",
        ])
    }
}
