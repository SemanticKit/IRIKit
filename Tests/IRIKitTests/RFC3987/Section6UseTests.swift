import Foundation
import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 6 use of IRIs")
    struct Section6UseTests {
        @Test(
            "Software interfaces that transfer IRIs to URI-only components use section 3.1 mapping.",
            arguments: [
                URIMappingCase(
                    iri: "https://example.com/résumé.html",
                    uri: "https://example.com/r%C3%A9sum%C3%A9.html"
                ),
                URIMappingCase(
                    iri: "/résumé.html",
                    uri: "/r%C3%A9sum%C3%A9.html"
                ),
            ]
        )
        func mapsIRITextForURIOnlyInterfaces(_ testCase: URIMappingCase) throws {
            let reference = try IRIReference(validating: testCase.iri)

            #expect(URL(reference).relativeString == testCase.uri)
        }

        @Test("Software interfaces and protocols that carry IRIs define their character encoding.")
        func mapsCarriedIRITextUsingUTF8URIForm() throws {
            let reference = try IRIReference(validating: "résumé.html")

            #expect(URL(reference).relativeString == "r%C3%A9sum%C3%A9.html")
        }

        @Test("IRI-to-URI mapping is applied as late as possible when crossing to URI-only components.")
        func storesIRITextUntilURIFormIsRequested() throws {
            let reference = try IRIReference(validating: "résumé.html")

            #expect(reference.rawValue == "résumé.html")
            #expect(URL(reference).relativeString == "r%C3%A9sum%C3%A9.html")
        }

        @Test("IRI-to-URI mapping is not applied between components that can handle IRIs.")
        func preservesIRITextBetweenIRICapableComponents() throws {
            let reference = try IRIReference(validating: "https://example.com/résumé.html")

            #expect(reference.rawValue == "https://example.com/résumé.html")
        }

        @Test(
            "Relative IRI references follow the same reference model as URI references after IRI parsing.",
            arguments: [
                "../résumé.html",
                "./雪",
                "?q=résumé",
                "#café",
            ]
        )
        func acceptsRelativeIRIReferences(_ referenceString: String) throws {
            let reference = try IRIReference(validating: referenceString)

            #expect(reference.rawValue == referenceString)
        }

        @Test("Generated URI form for original characters uses UTF-8 percent-encoding.")
        func usesUTF8ForOriginalCharacters() throws {
            let iri = try IRI(validating: "https://example.com/résumé.html")

            #expect(URL(iri).absoluteString == "https://example.com/r%C3%A9sum%C3%A9.html")
        }

        @Test("URI references with non-UTF-8 percent-encoded parts keep those octets while UTF-8 parts can become IRI characters.")
        func preservesNonUTF8PercentEncodedParts() throws {
            let reference = try IRIReference(validating: "http://www.example.org/r%E9sum%E9.xml#r%C3%A9sum%C3%A9")

            #expect(reference.rawValue == "http://www.example.org/r%E9sum%E9.xml#r%C3%A9sum%C3%A9")
            #expect(URL(reference).absoluteString == reference.rawValue)
        }

        @Test("Strict IRI entry rejects characters outside section 2.2 syntax.")
        func rejectsCharactersOutsideIRIEntrySyntax() {
            #expect(throws: IRIError.invalidIRIReference("résumé file.html")) {
                try IRIReference(validating: "résumé file.html")
            }
        }
    }
}
