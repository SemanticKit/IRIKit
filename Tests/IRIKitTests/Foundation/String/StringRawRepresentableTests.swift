import IRIKit
import Testing

@Suite("String RawRepresentable coverage")
struct StringRawRepresentableTests {
    @Test("String does not provide RawRepresentable in the Swift standard library; IRIKit must define any raw-value relationship on its own types.")
    func rawValueRelationshipBelongsOnIRIKitTypes() throws {
        let iri = try IRI(validating: "https://example.com/rosé")

        requireRawRepresentable(IRI.self)
        #expect(iri.rawValue == "https://example.com/rosé")
    }
}
