import Foundation
import IRIKit
import Testing

@Suite("URL RawRepresentable coverage")
struct URLRawRepresentableTests {
    @Test("URL does not declare RawRepresentable in Foundation documentation; IRI raw values store IRI character form.")
    func convertsURLAbsoluteStringToIRIRawValue() throws {
        let url = URL(string: "https://example.com/people/ren%C3%A9e?view=summary#details")!
        let iri = try IRI(url)

        requireRawRepresentable(IRI.self)
        #expect(iri.rawValue == "https://example.com/people/renée?view=summary#details")
        #expect(URL(iri).absoluteString == url.absoluteString)
    }
}
