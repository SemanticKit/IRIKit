import Foundation
import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 3.1 IRI to URI mapping extended cases")
    struct Section3IRIToURIMappingExtendedTests {
        @Test(
            "Step 2.2 maps each non-URI character to UTF-8 octets and percent-encodes each octet.",
            arguments: [
                URIMappingCase(
                    iri: "https://example.com/\u{00A0}",
                    uri: "https://example.com/%C2%A0"
                ),
                URIMappingCase(
                    iri: "https://example.com/\u{E1000}",
                    uri: "https://example.com/%F3%A1%80%80"
                ),
                URIMappingCase(
                    iri: "https://例え.テスト/",
                    uri: "https://%E4%BE%8B%E3%81%88.%E3%83%86%E3%82%B9%E3%83%88/"
                ),
            ]
        )
        func mapsUCSCharactersToUTF8PercentEncodedOctets(_ testCase: URIMappingCase) throws {
            let iri = try IRI(validating: testCase.iri)

            #expect(URL(iri).absoluteString == testCase.uri)
        }

        @Test(
            "Step 2.1 leaves valid URI characters unchanged.",
            arguments: [
                "https://example.com/a-z.A_Z~0-9",
                "https://example.com/!$&'()*+,;=:@",
                "https://example.com/path?query/with?reserved#fragment/with?reserved",
            ]
        )
        func leavesURICharactersUnchanged(_ iriString: String) throws {
            let iri = try IRI(validating: iriString)

            #expect(URL(iri).absoluteString == iriString)
        }

        @Test(
            "Systems MAY convert ireg-name using ToASCII before IRI-to-URI mapping.",
            arguments: [
                URIMappingCase(
                    iri: "http://r\u{00E9}sum\u{00E9}.example.org",
                    uri: "http://xn--rsum-bpad.example.org"
                )
            ]
        )
        func recordsOptionalToASCIIHostMappingBoundary(_ testCase: URIMappingCase) throws {
            let iri = try IRI(validating: testCase.iri)

            #expect(iri.rawValue == testCase.iri)
            #expect(testCase.uri == "http://xn--rsum-bpad.example.org")
        }
    }
}
