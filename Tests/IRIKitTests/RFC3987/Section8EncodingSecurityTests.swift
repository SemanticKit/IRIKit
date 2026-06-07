import Foundation
import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 8 encoding security")
    struct Section8EncodingSecurityTests {
        @Test("Overlong UTF-8 percent-encoded slash must not decode to '/'.")
        func preservesOverlongUTF8PercentEncoding() throws {
            let reference = try IRIReference(validating: "/%C0%AF")

            #expect(reference.rawValue == "/%C0%AF")
            #expect(URL(reference).relativeString == "/%C0%AF")
        }

        @Test("Reserved and unreserved characters must remain clearly distinguished during security checks.")
        func preservesReservedCharacterEncodingDistinctions() throws {
            let encodedSlash = try IRI(validating: "https://example.com/%2F")
            let literalSlash = try IRI(validating: "https://example.com//")

            #expect(encodedSlash != literalSlash)
            #expect(URL(encodedSlash).absoluteString == "https://example.com/%2F")
        }

        @Test("Legacy percent-encoded character encodings increase spoofing risk.")
        func preservesLegacyPercentEncodedOctets() throws {
            let iri = try IRI(validating: "https://example.com/r%E9sum%E9")

            #expect(iri.rawValue == "https://example.com/r%E9sum%E9")
            #expect(URL(iri).absoluteString == "https://example.com/r%E9sum%E9")
        }

        @Test("Bidi spoofing risk is controlled by section 4.2 component restrictions.")
        func rejectsBidiFormattingCharactersUsedForSpoofing() {
            #expect(throws: IRIError.invalidIRI("https://example.com/\u{202E}")) {
                try IRI(validating: "https://example.com/\u{202E}")
            }
        }

        @Test("Bidi security requires a correct Unicode bidirectional implementation.")
        func preservesBidiTextInLogicalOrder() throws {
            let iriString = "https://مثال.إختبار/مسار"
            let iri = try IRI(validating: iriString)

            #expect(iri.rawValue == iriString)
        }
    }
}
