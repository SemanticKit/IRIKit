/// The `iuserinfo`, `ihost`, and `port` subcomponents of a validated
/// authority.
struct IRIAuthorityParts: Equatable, Sendable {
    var userInfo: String?
    var host: String
    var port: String?

    init(_ authority: String) {
        var hostPort = Substring(authority)
        if let at = authority.firstIndex(of: "@") {
            userInfo = String(authority[..<at])
            hostPort = authority[authority.index(after: at)...]
        } else {
            userInfo = nil
        }

        let portSeparator: Substring.Index?
        if hostPort.hasPrefix("["), let closing = hostPort.firstIndex(of: "]") {
            let afterLiteral = hostPort.index(after: closing)
            portSeparator = afterLiteral < hostPort.endIndex ? afterLiteral : nil
        } else {
            portSeparator = hostPort.firstIndex(of: ":")
        }

        if let portSeparator {
            host = String(hostPort[..<portSeparator])
            port = String(hostPort[hostPort.index(after: portSeparator)...])
        } else {
            host = String(hostPort)
            port = nil
        }
    }

    /// Applies a text transformation to the user information and host.
    mutating func transformText(_ transform: (String) -> String) {
        userInfo = userInfo.map(transform)
        host = transform(host)
    }

    var isIPLiteral: Bool {
        host.hasPrefix("[")
    }

    var string: String {
        var result = ""
        if let userInfo {
            result += userInfo + "@"
        }
        result += host
        if let port {
            result += ":" + port
        }
        return result
    }
}
