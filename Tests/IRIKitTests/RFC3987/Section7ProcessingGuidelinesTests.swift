import Foundation
import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 7 processing guidelines")
    struct Section7ProcessingGuidelinesTests {
        @Test("URI-only transfer from an IRI input component maps the IRI to URI form.")
        func mapsIRIInputForURIOnlyTransfer() throws {
            let iri = try IRI(validating: "https://example.com/résumé.html")

            #expect(URL(iri).absoluteString == "https://example.com/r%C3%A9sum%C3%A9.html")
        }

        @Test("URI/IRI software interfaces and protocol elements define the character encoding used for IRIs.")
        func mapsOriginalCharactersWithUTF8PercentEncoding() throws {
            let iri = try IRI(validating: "https://example.com/雪")

            #expect(URL(iri).absoluteString == "https://example.com/%E9%9B%AA")
        }

        @Test("URI-only to IRI-capable transfer requires no mapping unless URI-to-IRI conversion is selected and safe.")
        func preservesURITextWithoutUnsafeInverseConversion() throws {
            let reference = try IRIReference(validating: "r%E9sum%E9.html")

            #expect(reference.rawValue == "r%E9sum%E9.html")
            #expect(URL(reference).relativeString == "r%E9sum%E9.html")
        }

        @Test("IRI-capable transfer preserves characters, not bytes.")
        func preservesCharactersForIRICapableTransfer() throws {
            let referenceString = "résumé.html"
            let reference = try IRIReference(validating: referenceString)

            #expect(reference.rawValue == referenceString)
        }

        @Test("Transfer detection treats non-ASCII characters as part of an IRI.")
        func acceptsNonASCIICharactersInsideDetectedIRI() throws {
            let reference = try IRIReference(validating: "https://example.com/résumé.html")

            #expect(reference.rawValue == "https://example.com/résumé.html")
        }

        @Test("IRI entry components enforce section 2.2 restrictions through input conversion, elimination, warning, or error.")
        func rejectsCharactersOutsideIRIEntrySyntax() {
            #expect(throws: IRIError.invalidIRIReference("résumé file.html")) {
                try IRIReference(validating: "résumé file.html")
            }
        }

        @Test("IRI entry can expose the mapped URI form when users need compatibility with URI-only software.")
        func exposesMappedURIForm() throws {
            let iri = try IRI(validating: "https://example.com/résumé.html")

            #expect(URL(iri).absoluteString == "https://example.com/r%C3%A9sum%C3%A9.html")
        }

        @Test("Clipboard transfer carries IRI text as characters rather than bytes.")
        func preservesCopiedIRITextAsCharacters() throws {
            let referenceString = "résumé.html"
            let reference = try IRIReference(validating: referenceString)

            #expect(reference.description == referenceString)
        }

        @Test("Generated resource identifiers transform local names to UTF-8-based URI form when exposing IRI-compatible resources.")
        func mapsGeneratedResourceIdentifiersToURIForm() throws {
            let iri = try IRI(validating: "https://example.com/résumé.html")

            #expect(URL(iri).absoluteString == "https://example.com/r%C3%A9sum%C3%A9.html")
        }

        @Test("Display form does not change the stored logical IRI character sequence.")
        func displayDoesNotChangeStoredLogicalSequence() throws {
            let iriString = "https://مثال.إختبار/مسار"
            let iri = try IRI(validating: iriString)

            #expect(iri.description == iriString)
            #expect(iri.rawValue == iriString)
        }
    }
}
