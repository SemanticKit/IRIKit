import Foundation
import IRIKit
import Testing

@Suite("URLComponents IRIComponents initializer coverage")
struct URLComponentsIRIComponentsInitializerTests {
    @Test("URLComponents should initialize IRIComponents from Foundation component storage.")
    func createsIRIComponents() {
        let urlComponents = URLComponents(string: "https://example.com/people/ren%C3%A9e?view=summary#details")!
        let components = IRIComponents(urlComponents)

        #expect(components.scheme == "https")
        #expect(components.authority == "example.com")
        #expect(components.path == "/people/ren%C3%A9e")
        #expect(components.query == "view=summary")
        #expect(components.fragment == "details")
    }
}
