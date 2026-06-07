import Foundation
import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 3.2.1 URI to IRI examples")
    struct Section3URIToIRIExamplesTests {
        @Test("The RFC example %C3%BC converts to U+00FC.")
        func convertsUmlautExample() throws {
            let iri = try IRI(URL(string: "http://www.example.org/D%C3%BCrst")!)

            #expect(iri.rawValue == "http://www.example.org/Dürst")
        }

        @Test("The RFC example %FC remains percent-encoded because it is not legal UTF-8.")
        func preservesInvalidUTF8Example() throws {
            let iri = try IRI(URL(string: "http://www.example.org/D%FCrst")!)

            #expect(iri.rawValue == "http://www.example.org/D%FCrst")
        }

        @Test("The RFC example %e2%80%ae remains percent-encoded because U+202E is forbidden.")
        func preservesBidiFormattingExample() throws {
            let iri = try IRI(URL(string: "http://xn--99zt52a.example.org/%e2%80%ae")!)

            #expect(iri.rawValue == "http://xn--99zt52a.example.org/%e2%80%ae")
        }

        @Test("Scheme-specific ToUnicode for punycode domain labels is optional.")
        func preservesPunycodeDomainWhenNoSchemeConversionIsSelected() throws {
            let iri = try IRI(URL(string: "http://xn--99zt52a.example.org/")!)

            #expect(iri.authority == "xn--99zt52a.example.org")
        }
    }
}
