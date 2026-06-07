import Foundation
import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 7.5 through 7.7 selection, display, and interpretation")
    struct Section7SelectionDisplayInterpretationTests {
        @Test("IRI selection should avoid confusable resource names.")
        func keepsConfusableResourceNamesDistinct() throws {
            let latin = try IRI(validating: "https://example.com/paypal")
            let cyrillic = try IRI(validating: "https://example.com/p\u{0430}ypal")

            #expect(latin != cyrillic)
        }

        @Test("IRI selection should avoid unnecessary compatibility characters.")
        func keepsCompatibilityCharactersDistinct() throws {
            let compatibility = try IRI(validating: "https://example.com/\u{FB01}")
            let ordinary = try IRI(validating: "https://example.com/fi")

            #expect(compatibility != ordinary)
        }

        @Test("IRI selection should avoid mixing unrelated scripts inside one component.")
        func acceptsMixedScriptsWithoutChangingIdentity() throws {
            let mixed = try IRI(validating: "https://example.com/a\u{0430}")
            let latin = try IRI(validating: "https://example.com/aa")

            #expect(mixed != latin)
        }

        @Test("IRI selection should prefer lowercase Latin, Greek, and Cyrillic where that reduces visual ambiguity.")
        func preservesCaseDifferences() throws {
            let upper = try IRI(validating: "https://example.com/A")
            let lower = try IRI(validating: "https://example.com/a")

            #expect(upper != lower)
        }

        @Test("Display may percent-encode non-ASCII parts when rendering support is unavailable.")
        func exposesPercentEncodedDisplayCompatibleURIForm() throws {
            let iri = try IRI(validating: "https://example.com/雪")

            #expect(URL(iri).absoluteString == "https://example.com/%E9%9B%AA")
        }

        @Test("IRI interpretation may accept native IRI and URI counterpart forms.")
        func preservesNativeAndURICounterpartForms() throws {
            let native = try IRI(validating: "https://example.com/résumé")
            let uri = try IRI(validating: "https://example.com/r%C3%A9sum%C3%A9")

            #expect(native != uri)
            #expect(URL(native).absoluteString == uri.rawValue)
        }

        @Test("Percent-encoded and non-percent-encoded parts remain distinguishable.")
        func distinguishesPercentEncodedAndCharacterForms() throws {
            let characterForm = try IRI(validating: "https://example.com/résumé")
            let percentForm = try IRI(validating: "https://example.com/r%C3%A9sum%C3%A9")

            #expect(characterForm.rawValue != percentForm.rawValue)
        }
    }
}
