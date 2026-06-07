import IRIKit

let canonical = try AbsoluteIRI(validating: "https://example.com/people/renée")

canonical.rawValue
// "https://example.com/people/renée"
