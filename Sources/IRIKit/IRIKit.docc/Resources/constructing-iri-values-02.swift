import IRIKit

let profile = try IRI(validating: "https://example.com/people/renée#summary")

profile.rawValue
// "https://example.com/people/renée#summary"

profile.scheme
// "https"

profile.path
// "/people/renée"

profile.fragment
// "summary"
