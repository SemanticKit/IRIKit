import IRIKit

var components = IRIComponents(
    scheme: "https",
    authority: "example.com",
    path: "/people/renée"
)

components.query = "view=summary"
components.fragment = "details"
