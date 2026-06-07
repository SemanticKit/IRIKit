import IRIKit
import Testing

@Suite("IRIReference Equatable coverage")
struct IRIReferenceEquatableTests {
    @Test("IRIReference provides Equatable by simple string identity.")
    func comparesSimpleStringIdentity() throws {
        let lhs = try IRIReference(validating: "../a")
        let rhs = try IRIReference(validating: "../a")
        let other = try IRIReference(validating: "../b")

        requireEquatable(IRIReference.self)
        #expect(lhs == rhs)
        #expect(lhs != other)
    }
}
