import IRIKit
import Testing

@Suite("AbsoluteIRI Comparable coverage")
struct AbsoluteIRIComparableTests {
    @Test("AbsoluteIRI provides Comparable using simple string ordering.")
    func sortsBySimpleStringOrdering() throws {
        let values = [
            try AbsoluteIRI(validating: "https://example.com/b"),
            try AbsoluteIRI(validating: "https://example.com/a"),
        ].sorted()

        requireComparable(AbsoluteIRI.self)
        #expect(values.map(\.rawValue) == [
            "https://example.com/a",
            "https://example.com/b",
        ])
    }
}
