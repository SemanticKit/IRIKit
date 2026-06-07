import Foundation
import IRIKit

var components = URLComponents()
components.scheme = "https"
components.host = "example.com"
components.path = "/people/renée"
components.query = "view=summary"

let iriComponents = IRIComponents(components)
let validated = try iriComponents.iri()

validated.rawValue
// "https://example.com/people/ren%C3%A9e?view=summary"
