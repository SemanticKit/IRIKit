import Foundation
import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 4.3 and 4.4 Bidi input and examples")
    struct Section4InputAndExamplesTests {
        @Test("Bidi input methods must generate logical-order IRIs.")
        func storesInputIRITextInLogicalOrder() throws {
            let iriString = "http://אב.גד.הו/זח/טי/כל"
            let iri = try IRI(validating: iriString)

            #expect(iri.rawValue == iriString)
        }

        @Test("Bidi rendering should update after each input character.")
        func validatesIntermediateLogicalOrderPrefixes() throws {
            let prefix = try IRIReference(validating: "אב")
            let extended = try IRIReference(validating: "אבג")

            #expect(prefix.rawValue == "אב")
            #expect(extended.rawValue == "אבג")
        }

        @Test(
            "Allowed Bidi examples preserve logical storage.",
            arguments: [
                "http://ab.אבגדהו.ij/kl/mn/op.html",
                "http://ab.אבג.דהו/ij/kl/mn/op.html",
                "http://אב.גד.הו/זח/טי/כל?מנ=סע;פצ=קר#שת",
                "http://אב.גד.ef/gh/טי/כל.html",
                "http://ab.cd.הו/זח/ij/kl.html",
                "http://ab.גד.הו/זח/טי/kl.html",
                "http://ab.אבג123דהו.ij/kl/mn/op.html",
                "http://ab.אבגדהו.123/kl/mn/op.html",
            ]
        )
        func storesAllowedBidiExamplesLogically(_ iriString: String) throws {
            let iri = try IRI(validating: iriString)

            #expect(iri.rawValue == iriString)
        }

        @Test("Bidi examples with numerals at component boundaries require section 4.2 policy.")
        func preservesNumeralBoundaryBidiExamplesForPolicyEvaluation() throws {
            let iri = try IRI(validating: "http://ab.אבג123דהו.ij/kl/mn/op.html")

            #expect(iri.rawValue == "http://ab.אבג123דהו.ij/kl/mn/op.html")
        }

        @Test("Bidi examples with percent-encoded numerals still require whole-component mapping policy.")
        func preservesPercentEncodedBidiComponentText() throws {
            let iri = try IRI(validating: "http://ab.%D7%90%D7%91%D7%92123.ij/kl")

            #expect(URL(iri).absoluteString == "http://ab.%D7%90%D7%91%D7%92123.ij/kl")
        }

        @Test("Numeric-only components adjacent to right-to-left components are allowed but not recommended.")
        func acceptsNumericComponentsAdjacentToRTLComponents() throws {
            let iri = try IRI(validating: "http://אב.123/שלום")

            #expect(iri.rawValue == "http://אב.123/שלום")
        }
    }
}
