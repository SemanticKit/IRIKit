import IRIKit
import Testing

@Suite("IRIReference Comparable coverage")
struct IRIReferenceComparableTests {
    @Test("IRIReference provides Comparable using simple string ordering.", .tags(.comparison))
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

    @Test("IRIReference orders canonically equivalent but unequal values by Unicode scalar value, consistent with ==.", .tags(.comparison))
    func ordersCanonicallyEquivalentValuesApart() throws {
        let composed = try IRIReference(validating: "r\u{E9}sum\u{E9}")
        let decomposed = try IRIReference(validating: "re\u{301}sume\u{301}")

        #expect(composed != decomposed)
        // U+0065 sorts before U+00E9, so the decomposed form comes first.
        #expect(decomposed < composed)
        #expect(!(composed < decomposed))
        #expect([composed, decomposed].sorted() == [decomposed, composed])
    }
}
