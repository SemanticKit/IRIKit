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

    @Test("IRI orders canonically equivalent but unequal values by Unicode scalar value, consistent with ==.")
    func ordersCanonicallyEquivalentValuesApart() throws {
        let composed = try IRI(validating: "http://example.org/r\u{E9}sum\u{E9}")
        let decomposed = try IRI(validating: "http://example.org/re\u{301}sume\u{301}")

        #expect(composed != decomposed)
        // U+0065 sorts before U+00E9, so the decomposed form comes first.
        #expect(decomposed < composed)
        #expect(!(composed < decomposed))
        #expect([composed, decomposed].sorted() == [decomposed, composed])
    }
}
