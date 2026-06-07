import Foundation
import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 3.2 URI to IRI conversion")
    struct Section3URIToIRIConversionTests {
        @Test("URI-to-IRI conversion decodes percent-encoded UTF-8 where allowed.")
        func convertsPercentEncodedUTF8ToIRICharacters() throws {
            let iri = try IRI(URL(string: "http://www.example.org/D%C3%BCrst")!)

            #expect(iri.rawValue == "http://www.example.org/Dürst")
        }

        @Test("URI-to-IRI conversion preserves invalid UTF-8 percent-encoded octets.")
        func preservesInvalidUTF8PercentEncodedOctets() throws {
            let iri = try IRI(URL(string: "http://www.example.org/D%FCrst")!)

            #expect(iri.rawValue == "http://www.example.org/D%FCrst")
        }

        @Test("URI-to-IRI conversion preserves reserved percent-encoded characters.")
        func preservesReservedPercentEncodedCharacters() throws {
            let iri = try IRI(URL(string: "http://example.com/%2F")!)

            #expect(iri.rawValue == "http://example.com/%2F")
        }

        @Test("URI-to-IRI conversion re-percent-encodes characters inappropriate for IRIs.")
        func preservesCharactersInappropriateForIRIs() throws {
            let iri = try IRI(URL(string: "http://xn--99zt52a.example.org/%e2%80%ae")!)

            #expect(iri.rawValue == "http://xn--99zt52a.example.org/%e2%80%ae")
        }
    }
}
