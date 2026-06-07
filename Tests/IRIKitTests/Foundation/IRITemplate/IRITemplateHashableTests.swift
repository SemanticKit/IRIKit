import IRIKit
import Testing

@Suite("IRITemplate Hashable coverage")
struct IRITemplateHashableTests {
    @Test("IRITemplate provides Hashable with equal templates collapsing to one set member.")
    func collapsesEqualValuesInASet() throws {
        let values: Set = [
            try IRITemplate(validating: "https://example.com/{name}"),
            try IRITemplate(validating: "https://example.com/{name}"),
            try IRITemplate(validating: "https://example.com/{id}"),
        ]

        requireHashable(IRITemplate.self)
        #expect(values.count == 2)
    }
}
