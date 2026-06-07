import Foundation
import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 3.1 IRI to URI mapping")
    struct Section3IRIToURIMappingTests {
        @Test(
            "Convert each character not allowed in a URI to one or more octets using UTF-8, then percent-encode each octet.",
            arguments: [
                URIMappingCase(
                    iri: "https://example.com/rosé?tag=雪#frag",
                    uri: "https://example.com/ros%C3%A9?tag=%E9%9B%AA#frag"
                ),
                URIMappingCase(
                    iri: "https://example.com/é",
                    uri: "https://example.com/%C3%A9"
                ),
                URIMappingCase(
                    iri: "https://example.com/𐌀",
                    uri: "https://example.com/%F0%90%8C%80"
                ),
            ]
        )
        func mapsIRICharactersToURICharacters(_ testCase: URIMappingCase) throws {
            let iri = try IRI(validating: testCase.iri)

            #expect(URL(iri).absoluteString == testCase.uri)
        }

        @Test(
            "The mapping is an identity transformation for URI characters and does not encode existing percent triplets again.",
            arguments: [
                "https://example.com/path?x=1#frag",
                "https://example.com/ros%C3%A9",
            ]
        )
        func preservesURICharacterSequences(_ iriString: String) throws {
            let iri = try IRI(validating: iriString)

            #expect(URL(iri).absoluteString == iriString)
        }
    }
}
