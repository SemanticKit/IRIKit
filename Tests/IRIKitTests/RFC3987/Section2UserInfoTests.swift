import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 2.2 userinfo syntax")
    struct Section2UserInfoTests {
        @Test(
            "iuserinfo = *( iunreserved / pct-encoded / sub-delims / ':' )",
            arguments: [
                "https://user@example.com/",
                "https://user:pass@example.com/",
                "https://r%C3%A9sum%C3%A9@example.com/",
                "https://!$&'()*+,;=:@example.com/",
                "https://用户@example.com/",
            ]
        )
        func acceptsUserInfoCharacters(_ iriString: String) throws {
            let iri = try IRI(validating: iriString)

            #expect(iri.rawValue == iriString)
        }

        @Test("Characters outside iuserinfo end authority or remain outside userinfo.")
        func parsesCharactersOutsideUserInfoAsOtherComponents() throws {
            let slash = try IRI(validating: "https://user/name@example.com/")
            let query = try IRI(validating: "https://user?name@example.com/")
            let fragment = try IRI(validating: "https://user#name@example.com/")

            #expect(slash.authority == "user")
            #expect(slash.path == "/name@example.com/")
            #expect(query.authority == "user")
            #expect(query.query == "name@example.com/")
            #expect(fragment.authority == "user")
            #expect(fragment.fragment == "name@example.com/")
        }

        @Test("userinfo is optional before ihost.")
        func acceptsAuthorityWithoutUserInfo() throws {
            let iri = try IRI(validating: "https://example.com/")

            #expect(iri.authority == "example.com")
        }

        @Test(
            "iuserinfo excludes gen-delims other than ':'.",
            arguments: [
                "https://user[name@example.com/",
                "https://user]name@example.com/",
            ]
        )
        func rejectsDisallowedUserInfoCharacters(_ iriString: String) {
            #expect(throws: IRIError.invalidIRI(iriString)) {
                try IRI(validating: iriString)
            }
        }
    }
}
