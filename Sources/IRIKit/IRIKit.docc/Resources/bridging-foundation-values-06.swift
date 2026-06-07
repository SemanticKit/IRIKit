import Foundation
import IRIKit

let relativeURL = URL(string: "../people/ren%C3%A9e#summary")!
let reference = try IRIReference(relativeURL)

reference.rawValue
// "../people/renée#summary"
