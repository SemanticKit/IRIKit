import Foundation
import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 3.2 URI to IRI preservation rules")
    struct Section3URIToIRIPreservationTests {
        @Test("URI-to-IRI conversion preserves percent-encoded percent signs.")
        func preservesPercentSignEncoding() throws {
            let reference = try IRIReference(URL(string: "%25")!)

            #expect(reference.rawValue == "%25")
        }

        @Test("URI-to-IRI conversion preserves percent-encoded reserved characters.")
        func preservesReservedCharacterEncodings() throws {
            let reference = try IRIReference(URL(string: "%2F%3F%23%5B%5D%40")!)

            #expect(reference.rawValue == "%2F%3F%23%5B%5D%40")
        }

        @Test("URI-to-IRI conversion preserves percent-encoded US-ASCII characters not allowed in URIs.")
        func preservesDisallowedASCIIEncodings() throws {
            let reference = try IRIReference(URL(string: "%3C%3E%22%20%7B%7D%7C%5C%5E%60")!)

            #expect(reference.rawValue == "%3C%3E%22%20%7B%7D%7C%5C%5E%60")
        }

        @Test("URI-to-IRI conversion must not guess non-UTF-8 character encodings.")
        func doesNotGuessNonUTF8Encodings() throws {
            let reference = try IRIReference(URL(string: "r%E9sum%E9.html")!)

            #expect(reference.rawValue == "r%E9sum%E9.html")
        }
    }
}
