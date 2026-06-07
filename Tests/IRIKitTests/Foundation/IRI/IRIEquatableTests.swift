import IRIKit
import Testing

@Suite("IRI Equatable coverage")
struct IRIEquatableTests {
    @Test("IRI provides Equatable by simple string identity.")
    func comparesSimpleStringIdentity() throws {
        let lhs = try IRI(validating: "https://example.com/a")
        let rhs = try IRI(validating: "https://example.com/a")
        let other = try IRI(validating: "https://example.com/b")

        requireEquatable(IRI.self)
        #expect(lhs == rhs)
        #expect(lhs != other)
    }
}
