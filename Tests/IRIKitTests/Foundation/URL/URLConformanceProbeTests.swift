import Foundation
import IRIKit
import Testing

@Suite("URL conformance probe")
struct URLConformanceProbeTests {
    enum ProtocolConformance: CustomStringConvertible, CaseIterable {
        case codable
        case equatable
        case customDebugStringConvertible
        case customStringConvertible
        case hashable
        case losslessStringConvertible

        var description: String {
            switch self {
            case .codable: "Codable"
            case .equatable: "Equatable"
            case .customDebugStringConvertible: "CustomDebugStringConvertible"
            case .customStringConvertible: "CustomStringConvertible"
            case .hashable: "Hashable"
            case .losslessStringConvertible: "LosslessStringConvertible"
            }
        }
    }

    fileprivate func conformsTo(
        _ iri: Any,
        _ conformance: ProtocolConformance,
        _ reference: Any,
        _ absoluteIRI: Any,
        _ template: Any,
        check: (Any) -> Bool
    ) {
        if !check(iri) { Issue.record("Foundation URL conforms to \(conformance); IRI is missing it.") }
        if !check(reference) { Issue.record("Foundation URL conforms to \(conformance); IRIReference is missing it.") }
        if !check(absoluteIRI) { Issue.record("Foundation URL conforms to \(conformance); AbsoluteIRI is missing it.") }
        if !check(template) { Issue.record("Foundation URL conforms to \(conformance); IRITemplate is missing it.") }
    }

    @Test("IRIKit URL peers support Foundation URL conformances.", arguments: ProtocolConformance.allCases)
    func conformanceParity(_ conformance: ProtocolConformance) {
        let url: Any = URL(string: "https://example.com/people/ren%C3%A9e")!
        let iri: Any = IRI("https://example.com/people/renée")
        let reference: Any = IRIReference("https://example.com/people/renée")
        let absoluteIRI: Any = AbsoluteIRI("https://example.com/people/renée")
        let template: Any = IRITemplate("https://example.com/people/{name}")

        switch conformance {
        case .codable:
            guard url is any Codable else { return }
            conformsTo(iri, conformance, reference, absoluteIRI, template) { $0 is any Codable }
        case .equatable:
            guard url is any Equatable else { return }
            conformsTo(iri, conformance, reference, absoluteIRI, template) { $0 is any Equatable }
        case .customDebugStringConvertible:
            guard url is any CustomDebugStringConvertible else { return }
            conformsTo(iri, conformance, reference, absoluteIRI, template) { $0 is any CustomDebugStringConvertible }
        case .customStringConvertible:
            guard url is any CustomStringConvertible else { return }
            conformsTo(iri, conformance, reference, absoluteIRI, template) { $0 is any CustomStringConvertible }
        case .hashable:
            guard url is any Hashable else { return }
            conformsTo(iri, conformance, reference, absoluteIRI, template) { $0 is any Hashable }
        case .losslessStringConvertible:
            guard url is any LosslessStringConvertible else { return }
            conformsTo(iri, conformance, reference, absoluteIRI, template) { $0 is any LosslessStringConvertible }
        }
    }
}
