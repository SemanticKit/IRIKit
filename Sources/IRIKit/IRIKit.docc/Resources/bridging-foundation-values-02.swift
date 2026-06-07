import Foundation
import IRIKit

let iri = try IRI(validating: "https://example.com/people/renée")
let url = URL(iri)

url.absoluteString
// "https://example.com/people/ren%C3%A9e"
