/// The `iuserinfo`, `ihost`, and `port` subcomponents of a validated
/// authority.
struct IRIAuthorityParts: Equatable, Sendable {
    var userInfo: String?
    var host: String
    var port: String?

    /// Splits a validated authority at its delimiters.
    ///
    /// The search runs on Unicode scalars, as ``IRIParser`` does, so a
    /// combining mark after `@` or `:` does not hide the delimiter.
    init(_ authority: String) {
        let scalars = Array(authority.unicodeScalars)[...]
        var hostPort = scalars
        if let at = scalars.firstIndex(of: "@") {
            userInfo = IRIParser.text(scalars[..<at])
            hostPort = scalars[(at + 1)...]
        } else {
            userInfo = nil
        }

        let portSeparator: Int?
        if hostPort.first == "[", let closing = hostPort.firstIndex(of: "]") {
            let afterLiteral = closing + 1
            portSeparator = afterLiteral < hostPort.endIndex ? afterLiteral : nil
        } else {
            portSeparator = hostPort.firstIndex(of: ":")
        }

        if let portSeparator {
            host = IRIParser.text(hostPort[..<portSeparator])
            port = IRIParser.text(hostPort[(portSeparator + 1)...])
        } else {
            host = IRIParser.text(hostPort)
            port = nil
        }
    }

    /// Applies a text transformation to the user information and host.
    mutating func transformText(_ transform: (String) -> String) {
        userInfo = userInfo.map(transform)
        host = transform(host)
    }

    var isIPLiteral: Bool {
        host.unicodeScalars.first == "["
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
