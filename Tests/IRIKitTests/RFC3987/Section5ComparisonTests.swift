import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 5.3.1 simple string comparison")
    struct Section5SimpleStringComparisonTests {
        @Test(
            "Simple string comparison compares the IRI character sequences for exact equality.",
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
    }
}
