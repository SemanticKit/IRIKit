import IRIKit
import Testing

@Suite("IRI Hashable coverage")
struct IRIHashableTests {
    @Test("IRI provides Hashable with equal identifiers collapsing to one set member.")
    func collapsesEqualValuesInASet() throws {
        let values: Set = [
            try IRI(validating: "https://example.com/a"),
            try IRI(validating: "https://example.com/a"),
            try IRI(validating: "https://example.com/b"),
        ]

        requireHashable(IRI.self)
        #expect(values.count == 2)
    }
}
