import IRIKit

let components = IRIComponents(
    scheme: "https",
    authority: "example.com",
    path: "/people/renée",
    query: "view=summary",
    fragment: "details"
)

components.string
// "https://example.com/people/renée?view=summary#details"
