import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 2.2 registry name syntax")
    struct Section2RegistryNameTests {
        @Test(
            "ireg-name = *( iunreserved / pct-encoded / sub-delims )",
            arguments: [
                "https://example.com/",
                "https://résumé.example/",
                "https://%72%C3%A9sum%C3%A9.example/",
                "https://!$&'()*+,;=.example/",
            ]
        )
        func acceptsRegistryNameCharacters(_ iriString: String) throws {
            let iri = try IRI(validating: iriString)

            #expect(iri.rawValue == iriString)
        }

        @Test(
            "ireg-name does not include ':' or '@'.",
            arguments: [
                "https://exa:mple.com/",
            ]
        )
        func rejectsRegistryNameCharactersOutsideProduction(_ iriString: String) {
            #expect(throws: IRIError.invalidIRI(iriString)) {
                try IRI(validating: iriString)
            }
        }

        @Test("Empty ireg-name is valid when the grammar selects the registry-name alternative.")
        func acceptsEmptyRegistryName() throws {
            let reference = try IRIReference(validating: "//")

            #expect(reference.rawValue == "//")
        }

        @Test(
            "An absolute IRI may have an empty ireg-name.",
            arguments: [
                ("file:///etc/hosts", "/etc/hosts"),
                ("file:///a/bb/ccc/d;p?q", "/a/bb/ccc/d;p"),
                ("urn://", ""),
                ("urn:////path", "//path"),
            ]
        )
        func acceptsAbsoluteIRIWithEmptyRegistryName(_ iriString: String, path: String) throws {
            let iri = try IRI(validating: iriString)

            #expect(iri.rawValue == iriString)
            #expect(iri.authority == "")
            #expect(iri.path == path)
        }
    }
}
