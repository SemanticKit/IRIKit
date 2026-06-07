import Foundation
import IRIKit

let canonicalURL = URL(string: "https://example.com/people/ren%C3%A9e")!
let canonical = try AbsoluteIRI(canonicalURL)

canonical.rawValue
// "https://example.com/people/renée"
