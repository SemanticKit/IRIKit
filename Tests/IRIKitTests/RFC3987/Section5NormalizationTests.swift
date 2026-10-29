import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 5.3.2 syntax-based normalization")
    struct Section5NormalizationTests {
        @Test("Simple string comparison MUST NOT map IRIs to URIs.")
        func simpleStringComparisonDoesNotMapToURI() throws {
            let iri = try IRI(validating: "https://example.com/rosé")
            let uriForm = try IRI(validating: "https://example.com/ros%C3%A9")

            #expect(iri != uriForm)
        }

        @Test("Syntax-based normalization uppercases percent-encoding hex digits.")
        func exactIdentityPreservesPercentEncodingCase() throws {
            let lowercase = try IRI(validating: "https://example.com/%3a")
            let uppercase = try IRI(validating: "https://example.com/%3A")

            #expect(lowercase != uppercase)
            #expect(try lowercase.normalized(.syntaxBased) == uppercase)
        }

        @Test("Syntax-based normalization lowercases scheme and ASCII-only host.")
        func exactIdentityPreservesSchemeAndHostCase() throws {
            let mixed = try IRI(validating: "HTTP://www.EXAMPLE.com/")
            let lower = try IRI(validating: "http://www.example.com/")

            #expect(mixed != lower)
            #expect(try mixed.normalized(.syntaxBased) == lower)
        }

        @Test("Syntax-based normalization decodes percent-encoded unreserved characters.")
        func exactIdentityPreservesPercentEncodedUnreservedCharacters() throws {
            let encoded = try IRI(validating: "http://example.org/%7Euser")
            let decoded = try IRI(validating: "http://example.org/~user")

            #expect(encoded != decoded)
            #expect(try encoded.normalized(.syntaxBased) == decoded)
        }

        @Test("Syntax-based normalization removes dot-segments from paths.")
        func exactIdentityPreservesDotSegments() throws {
            let dotted = try IRI(validating: "http://example.org/a/../b")
            let normalized = try IRI(validating: "http://example.org/b")

            #expect(dotted != normalized)
            #expect(try dotted.normalized(.syntaxBased) == normalized)
        }

        @Test(
            "Case normalization lowercases the scheme and a US-ASCII host and uppercases percent-encoding hex digits.",
            .tags(.normalization),
            arguments: [
                NormalizationCase("HTTP://www.EXAMPLE.com/", .letterCase, expected: "http://www.example.com/"),
                NormalizationCase("https://example.com/%3a", .letterCase, expected: "https://example.com/%3A"),
                NormalizationCase("https://example.com/a?q=%e2%82%ac#%c3", .letterCase, expected: "https://example.com/a?q=%E2%82%AC#%C3"),
                NormalizationCase("https://User@Example.COM/Path", .letterCase, expected: "https://User@example.com/Path"),
                NormalizationCase("https://%7EUser@%E2xample.com/", .letterCase, expected: "https://%7EUser@%E2xample.com/"),
                NormalizationCase("http://[FE80::A]:8080/", .letterCase, expected: "http://[fe80::a]:8080/"),
                NormalizationCase("https://BÜCHER.Example/", .letterCase, expected: "https://BÜCHER.Example/"),
                NormalizationCase("URN:example:Animal:ferret:nose", .letterCase, expected: "urn:example:Animal:ferret:nose"),
            ]
        )
        func caseNormalization(_ testCase: NormalizationCase) throws {
            let iri = try IRI(validating: testCase.input)

            #expect(try iri.normalized(testCase.normalization).rawValue == testCase.expected)
        }

        @Test(
            "Percent-encoding normalization decodes octets that correspond to iunreserved characters only.",
            .tags(.normalization),
            arguments: [
                NormalizationCase("http://example.org/%7Euser", .percentEncoding, expected: "http://example.org/~user"),
                NormalizationCase("http://example.org/%7euser", .percentEncoding, expected: "http://example.org/~user"),
                NormalizationCase("http://example.org/%41%2d%5F%2E", .percentEncoding, expected: "http://example.org/A-_."),
                NormalizationCase("https://example.com/ros%C3%A9", .percentEncoding, expected: "https://example.com/rosé"),
                NormalizationCase("https://ex%61mple.com/?q=%E9%9B%AA#%c3%a9", .percentEncoding, expected: "https://example.com/?q=雪#é"),
                NormalizationCase("http://example.org/a%2Fb%3F%23%25%20", .percentEncoding, expected: "http://example.org/a%2Fb%3F%23%25%20"),
                NormalizationCase("http://example.org/%C3", .percentEncoding, expected: "http://example.org/%C3"),
                NormalizationCase("http://example.org/%C3%28", .percentEncoding, expected: "http://example.org/%C3%28"),
                NormalizationCase("http://example.org/%E2%80%8F", .percentEncoding, expected: "http://example.org/%E2%80%8F"),
                NormalizationCase("http://example.org/?%EE%80%80", .percentEncoding, expected: "http://example.org/?%EE%80%80"),
            ]
        )
        func percentEncodingNormalization(_ testCase: NormalizationCase) throws {
            let iri = try IRI(validating: testCase.input)

            #expect(try iri.normalized(testCase.normalization).rawValue == testCase.expected)
        }

        @Test(
            "Path segment normalization applies remove_dot_segments from RFC 3986 section 5.2.4.",
            .tags(.normalization),
            arguments: [
                NormalizationCase("http://example.org/a/../b", .pathSegments, expected: "http://example.org/b"),
                NormalizationCase("http://a/b/c/./../../g", .pathSegments, expected: "http://a/g"),
                NormalizationCase("http://example.org/a/./b/../c", .pathSegments, expected: "http://example.org/a/c"),
                NormalizationCase("http://example.org/a/b/", .pathSegments, expected: "http://example.org/a/b/"),
                NormalizationCase("http://example.org/a/.", .pathSegments, expected: "http://example.org/a/"),
                NormalizationCase("http://example.org/a/..", .pathSegments, expected: "http://example.org/"),
                NormalizationCase("http://example.org/../../x", .pathSegments, expected: "http://example.org/x"),
                NormalizationCase("http://example.org/a//b/./c", .pathSegments, expected: "http://example.org/a//b/c"),
                NormalizationCase("http://example.org/a.b/..c/d.", .pathSegments, expected: "http://example.org/a.b/..c/d."),
                NormalizationCase("http://example.org/a?x=/../y#/./z", .pathSegments, expected: "http://example.org/a?x=/../y#/./z"),
                NormalizationCase("example:mid/content=5/../6", .pathSegments, expected: "example:mid/6"),
            ]
        )
        func pathSegmentNormalization(_ testCase: NormalizationCase) throws {
            let iri = try IRI(validating: testCase.input)

            #expect(try iri.normalized(testCase.normalization).rawValue == testCase.expected)
        }

        @Test(
            "Path segment normalization runs remove_dot_segments as written for a rootless path (RFC 3986 section 5.2.4).",
            .tags(.normalization),
            arguments: [
                // Step 2C removes "a" and its "/" and then writes "/b", so the
                // rootless path becomes "/b", as RFC 3986 section 5.2.2 also
                // gives for "foo:a/../b" (T.path = remove_dot_segments(R.path)).
                NormalizationCase("foo:a/../b", .pathSegments, expected: "foo:/b"),
                NormalizationCase("foo:a/..", .pathSegments, expected: "foo:/"),
                NormalizationCase("foo:.//b", .pathSegments, expected: "foo:/b"),
                NormalizationCase("foo:a/b/../c/./d", .pathSegments, expected: "foo:a/c/d"),
                NormalizationCase("foo:../a", .pathSegments, expected: "foo:a"),
                NormalizationCase("foo:mid/content=5/../6", .pathSegments, expected: "foo:mid/6"),
            ]
        )
        func rootlessPathFollowsTheAlgorithm(_ testCase: NormalizationCase) throws {
            let iri = try IRI(validating: testCase.input)
            let normalized = try iri.normalized(testCase.normalization)

            #expect(normalized.rawValue == testCase.expected)
            #expect(try normalized.normalized(testCase.normalization) == normalized)
        }

        @Test(
            "Path segment normalization keeps the path when remove_dot_segments would start it with // and there is no authority (RFC 3986 section 3.3).",
            .tags(.normalization),
            arguments: [
                // remove_dot_segments gives "//b" and "//bar". Without an
                // authority that text would be read as the authority "b" or
                // "bar", a different IRI, so the path is kept as it is.
                SimpleComparisonCase(lhs: "foo:a/../..//b", rhs: "foo://b", areEqual: false),
                SimpleComparisonCase(lhs: "example:/.//bar", rhs: "example://bar", areEqual: false),
                SimpleComparisonCase(lhs: "example:/a/..//bar", rhs: "example://bar", areEqual: false),
            ]
        )
        func pathThatWouldReadAsAnAuthorityIsKept(_ testCase: SimpleComparisonCase) throws {
            let iri = try IRI(validating: testCase.lhs)
            let normalized = try iri.normalized(.pathSegments)

            #expect(normalized == iri)
            #expect(normalized.authority == nil)
            #expect(try normalized.normalized(.pathSegments) == normalized)
            #expect(try iri.isEquivalent(to: IRI(validating: testCase.rhs), under: .syntaxBased) == testCase.areEqual)
        }

        @Test(
            "Percent-encoding normalization runs before dot-segment removal.",
            .tags(.normalization)
        )
        func decodesEncodedDotSegmentsBeforeRemovingThem() throws {
            let iri = try IRI(validating: "http://example.org/a/%2E%2E/b")

            #expect(try iri.normalized().rawValue == "http://example.org/b")
        }

        @Test(
            "Syntax-based normalization makes the RFC 3987 section 5.3.2 example IRIs equivalent.",
            .tags(.normalization)
        )
        func sectionExampleIsEquivalent() throws {
            let lhs = try IRI(validating: "example://a/b/c/%7Bfoo%7D/rosé")
            let rhs = try IRI(validating: "eXAMPLE://a/./b/../b/%63/%7bfoo%7d/ros%C3%A9")

            #expect(lhs != rhs)
            #expect(try lhs.isEquivalent(to: rhs))
            #expect(try rhs.normalized().rawValue == "example://a/b/c/%7Bfoo%7D/rosé")
        }

        @Test(
            "Normalization returns a new value and preserves the original form.",
            .tags(.normalization)
        )
        func preservesOriginalForm() throws {
            let original = try IRI(validating: "HTTP://Example.com/%7euser/./a")
            let normalized = try original.normalized()

            #expect(original.rawValue == "HTTP://Example.com/%7euser/./a")
            #expect(normalized.rawValue == "http://example.com/~user/a")
            #expect(try normalized.normalized() == normalized)
        }

        @Test(
            "Each exact-identity distinction in this section is removed by syntax-based normalization.",
            .tags(.normalization),
            arguments: [
                SimpleComparisonCase(lhs: "https://example.com/%3a", rhs: "https://example.com/%3A", areEqual: true),
                SimpleComparisonCase(lhs: "HTTP://www.EXAMPLE.com/", rhs: "http://www.example.com/", areEqual: true),
                SimpleComparisonCase(lhs: "http://example.org/%7Euser", rhs: "http://example.org/~user", areEqual: true),
                SimpleComparisonCase(lhs: "http://example.org/a/../b", rhs: "http://example.org/b", areEqual: true),
                SimpleComparisonCase(lhs: "https://example.com/rosé", rhs: "https://example.com/ros%C3%A9", areEqual: true),
                SimpleComparisonCase(lhs: "http://example.org/A", rhs: "http://example.org/a", areEqual: false),
                SimpleComparisonCase(lhs: "http://example.org/a%2Fb", rhs: "http://example.org/a/b", areEqual: false),
            ]
        )
        func syntaxBasedEquivalence(_ testCase: SimpleComparisonCase) throws {
            let lhs = try IRI(validating: testCase.lhs)
            let rhs = try IRI(validating: testCase.rhs)

            #expect(try lhs.isEquivalent(to: rhs) == testCase.areEqual)
        }

        @Test(
            "Absolute IRIs normalize with the same syntax-based rules.",
            .tags(.normalization)
        )
        func normalizesAbsoluteIRIs() throws {
            let lhs = try AbsoluteIRI(validating: "HTTP://Example.com/a/./%62")
            let rhs = try AbsoluteIRI(validating: "http://example.com/a/b")

            #expect(lhs != rhs)
            #expect(try lhs.normalized() == rhs)
            #expect(try lhs.isEquivalent(to: rhs))
        }
    }
}
