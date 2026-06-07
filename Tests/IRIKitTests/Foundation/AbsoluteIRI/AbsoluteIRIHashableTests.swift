import IRIKit
import Testing

@Suite("AbsoluteIRI Hashable coverage")
struct AbsoluteIRIHashableTests {
    @Test("AbsoluteIRI provides Hashable with equal identifiers collapsing to one set member.")
    func collapsesEqualValuesInASet() throws {
        let values: Set = [
            try AbsoluteIRI(validating: "https://example.com/a"),
            try AbsoluteIRI(validating: "https://example.com/a"),
            try AbsoluteIRI(validating: "https://example.com/b"),
        ]

        requireHashable(AbsoluteIRI.self)
        #expect(values.count == 2)
    }
}
