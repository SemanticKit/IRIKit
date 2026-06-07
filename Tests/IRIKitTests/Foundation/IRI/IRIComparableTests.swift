import IRIKit
import Testing

@Suite("IRI Comparable coverage")
struct IRIComparableTests {
    @Test("IRI provides Comparable using simple string ordering.")
    func sortsBySimpleStringOrdering() throws {
        let values = [
            try IRI(validating: "https://example.com/b"),
            try IRI(validating: "https://example.com/a"),
        ].sorted()

        requireComparable(IRI.self)
        #expect(values.map(\.rawValue) == [
            "https://example.com/a",
            "https://example.com/b",
        ])
    }
}
