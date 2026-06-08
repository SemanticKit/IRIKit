import IRIKit

let components = IRIComponents(
    scheme: "https",
    authority: "example.com",
    path: "/people/renée",
    query: "view=summary",
    fragment: "details"
)

let iri = try IRI(components: components)

iri.query
// "view=summary"
