import Foundation
import IRIKit
import Testing

@Suite("IRI query items")
struct IRIQueryItemTests {
    @Test func assemblesQueryItemsWithUnicodeValues() {
        let queryItems = [
            IRIQueryItem(name: "person", value: "renée"),
            IRIQueryItem(name: "view", value: "summary"),
        ]

        let query = queryItems.map(\.string).joined(separator: "&")

        #expect(query == "person=renée&view=summary")
    }

    @Test func distinguishesNilAndEmptyValues() {
        let absent = IRIQueryItem(name: "flag")
        let empty = IRIQueryItem(name: "empty", value: "")
        let present = IRIQueryItem(name: "name", value: "renée")

        #expect(absent.string == "flag")
        #expect(empty.string == "empty=")
        #expect(present.string == "name=renée")
    }

    @Test func buildsValidIRIThroughComponents() throws {
        let components = IRIComponents(
            scheme: "https",
            authority: "example.com",
            path: "/people",
            queryItems: [
                IRIQueryItem(name: "name", value: "renée"),
                IRIQueryItem(name: "active"),
                IRIQueryItem(name: "empty", value: ""),
            ],
            fragment: "details"
        )

        let iri = try IRI(components: components)

        #expect(
            components.string
                == "https://example.com/people?name=renée&active&empty=#details"
        )
        #expect(iri.query == "name=renée&active&empty=")
        #expect(iri.fragment == "details")
    }

    @Test func omitsQueryWhenQueryItemsAreEmpty() {
        let components = IRIComponents(
            scheme: "https",
            authority: "example.com",
            path: "/people",
            queryItems: []
        )

        #expect(components.string == "https://example.com/people")
        #expect(components.query == nil)
    }

    @Test func reportsInvalidQueryCharactersThroughIRIValidation() {
        let components = IRIComponents(
            scheme: "https",
            authority: "example.com",
            path: "/search",
            queryItems: [
                IRIQueryItem(name: "bad%", value: "value")
            ]
        )

        #expect(throws: IRIError.invalidIRI("https://example.com/search?bad%=value")) {
            try IRI(components: components)
        }
    }

    @Test func encodesAndDecodesNameAndValue() throws {
        let item = IRIQueryItem(name: "person", value: "renée")
        let encoded = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(IRIQueryItem.self, from: encoded)

        requireCodable(IRIQueryItem.self)
        requireEquatable(IRIQueryItem.self)
        #expect(decoded == item)
    }

    @Test func collapsesEqualValuesInASet() {
        let item = IRIQueryItem(name: "person", value: "renée")
        let values: Set = [item, item]

        requireHashable(IRIQueryItem.self)
        #expect(values.count == 1)
    }

    @Test func describesAssembledQueryItem() {
        let item = IRIQueryItem(name: "person", value: "renée")

        requireCustomStringConvertible(IRIQueryItem.self)
        #expect(item.description == "person=renée")
    }

    @Test func isSendable() {
        requireSendable(IRIQueryItem.self)
    }
}
