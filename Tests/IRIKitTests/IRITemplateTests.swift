import Foundation
import IRIKit
import Testing

@Suite("IRI templates")
struct IRITemplateTests {
    @Test func buildsIRIFromReusableBaseAndDynamicPathValues() throws {
        let template = try IRITemplate(validating: "https://example.com/{collection}/{name}")

        let iri = try template.expand([
            "collection": "things",
            "name": "rosé",
        ])

        #expect(iri.rawValue == "https://example.com/things/rosé")
        #expect(URL(iri).absoluteString == "https://example.com/things/ros%C3%A9")
    }

    @Test func reportsTemplateAuthoringAndExpansionErrors() throws {
        let template = try IRITemplate(validating: "https://example.com/{name}")

        #expect(throws: IRIError.missingTemplateValue("name")) {
            try template.expand([:])
        }

        #expect(throws: IRIError.invalidTemplate("https://example.com/{name")) {
            try IRITemplate(validating: String("https://example.com/{name"))
        }
    }
}
