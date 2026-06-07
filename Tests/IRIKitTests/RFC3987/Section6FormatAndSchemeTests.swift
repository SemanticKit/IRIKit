import Foundation
import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 6.3 and 6.4 document, protocol, and scheme use")
    struct Section6FormatAndSchemeTests {
        @Test("Documents and protocols carry IRI text as characters, not bytes.")
        func storesDocumentIRITextAsCharacters() throws {
            let iri = try IRI(validating: "https://example.com/résumé")

            #expect(iri.rawValue == "https://example.com/résumé")
        }

        @Test("Documents with native character encodings encode IRIs in the document encoding.")
        func preservesNativeDocumentCharacterSequence() throws {
            let iriString = "https://example.com/雪"
            let iri = try IRI(validating: iriString)

            #expect(iri.rawValue == iriString)
        }

        @Test("IRI characters not expressible in a document encoding use document escaping or section 3.1 percent-encoding.")
        func exposesPercentEncodingForDocumentEscapingBoundaries() throws {
            let iri = try IRI(validating: "https://example.com/雪")

            #expect(URL(iri).absoluteString == "https://example.com/%E9%9B%AA")
        }

        @Test("Non-UTF-8 documents must not embed IRI text using UTF-8 bytes.")
        func storesCharactersRatherThanUTF8ByteText() throws {
            let iri = try IRI(validating: "https://example.com/é")

            #expect(iri.rawValue == "https://example.com/é")
            #expect(iri.rawValue != "https://example.com/%C3%A9")
        }

        @Test("URI-only protocol elements receive URI form, not direct IRI form.")
        func mapsDirectIRIToURIForURIOnlyProtocolElements() throws {
            let iri = try IRI(validating: "https://example.com/résumé.html")

            #expect(URL(iri).absoluteString == "https://example.com/r%C3%A9sum%C3%A9.html")
        }

        @Test("There is no separate IRI scheme namespace.")
        func usesTheSchemeFromTheIdentifier() throws {
            let iri = try IRI(validating: "https://example.com/résumé")

            #expect(iri.scheme == "https")
        }

        @Test("Scheme-specific restrictions apply after section 3.1 URI mapping.")
        func genericSyntaxDoesNotRewriteSchemeSpecificContent() throws {
            let iri = try IRI(validating: "custom:résumé")

            #expect(iri.rawValue == "custom:résumé")
            #expect(URL(iri).absoluteString == "custom:r%C3%A9sum%C3%A9")
        }

        @Test("Percent-encoded non-UTF-8 path octets remain percent-encoded when only a fragment is UTF-8.")
        func preservesMixedEncodedURIReferenceParts() throws {
            let reference = try IRIReference(validating: "http://www.example.org/r%E9sum%E9.xml#r%C3%A9sum%C3%A9")

            #expect(reference.rawValue == "http://www.example.org/r%E9sum%E9.xml#r%C3%A9sum%C3%A9")
            #expect(URL(reference).absoluteString == reference.rawValue)
        }

        @Test("The HTTP URL scheme can only have corresponding different IRIs where original characters use UTF-8 percent-encoding.")
        func preservesNonUTF8PercentEncodedHTTPPath() throws {
            let iri = try IRI(validating: "http://example.com/r%E9sum%E9")

            #expect(URL(iri).absoluteString == "http://example.com/r%E9sum%E9")
        }

        @Test("IRI support does not upgrade any URI scheme specification.")
        func keepsSchemeSpecificIdentifierTextUnchanged() throws {
            let iri = try IRI(validating: "urn:example:résumé")

            #expect(iri.scheme == "urn")
            #expect(iri.rawValue == "urn:example:résumé")
        }
    }
}
