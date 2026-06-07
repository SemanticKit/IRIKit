import Foundation
import IRIKit

let url = URL(string: "https://example.com/people/ren%C3%A9e")!
let iri = try IRI(url)

iri.rawValue
// "https://example.com/people/renée"
