import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 5.3.1 simple string comparison")
    struct Section5SimpleStringComparisonTests {
        @Test(
            "Simple string comparison compares the IRI character sequences for exact equality.",
            .tags(.comparison),
            arguments: [
                SimpleComparisonCase(
                    lhs: "https://example.com/é",
                    rhs: "https://example.com/e\u{301}",
                    areEqual: false
                ),
                SimpleComparisonCase(
                    lhs: "https://example.com/a",
                    rhs: "https://example.com/a",
                    areEqual: true
                ),
            ]
        )
        func comparesExactCharacterSequences(_ testCase: SimpleComparisonCase) throws {
            let lhs = try IRI(validating: testCase.lhs)
            let rhs = try IRI(validating: testCase.rhs)

            #expect((lhs == rhs) == testCase.areEqual)
        }

        @Test(
            "Simple string comparison can be used to order exact IRI character sequences.",
            .tags(.comparison),
            arguments: [
                OrderedComparisonCase(
                    lower: "https://example.com/a",
                    upper: "https://example.com/b"
                )
            ]
        )
        func ordersExactCharacterSequences(_ testCase: OrderedComparisonCase) throws {
            let lower = try IRI(validating: testCase.lower)
            let upper = try IRI(validating: testCase.upper)

            #expect(lower < upper)
        }

        @Test(
            "Normalized comparison still begins from simple string comparison: identical IRIs stay equivalent.",
            .tags(.normalization),
            arguments: [
                "https://example.com/a",
                "urn:example:Animal:ferret:nose",
                "http://example.com/?",
                "http://example.com/#",
            ]
        )
        func identicalIRIsAreEquivalent(_ string: String) throws {
            let lhs = try IRI(validating: string)
            let rhs = try IRI(validating: string)

            #expect(lhs == rhs)
            #expect(try lhs.isEquivalent(to: rhs))
            #expect(try lhs.isEquivalent(to: rhs, under: .syntaxAndSchemeBased))
        }

        @Test(
            "An empty normalization set compares like simple string comparison.",
            .tags(.normalization)
        )
        func emptyNormalizationIsSimpleComparison() throws {
            let lhs = try IRI(validating: "HTTP://example.com/%7e")
            let rhs = try IRI(validating: "http://example.com/~")

            #expect(try lhs.normalized([]) == lhs)
            #expect(try !lhs.isEquivalent(to: rhs, under: []))
        }
    }
}
