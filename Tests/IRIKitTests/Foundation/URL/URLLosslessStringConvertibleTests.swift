import Foundation
import IRIKit
import Testing

@Suite("URL LosslessStringConvertible coverage")
struct URLLosslessStringConvertibleTests {
    @Test("URL does not declare LosslessStringConvertible in Foundation documentation; IRIKit converts URL text through IRI character form.")
    func convertsThroughIRICharacterForm() throws {
        let url = URL(string: "https://example.com/ros%C3%A9")!
        let iri = try IRI(url)

        #expect(iri.rawValue == "https://example.com/rosé")
        #expect(URL(iri).absoluteString == "https://example.com/ros%C3%A9")
    }
}
