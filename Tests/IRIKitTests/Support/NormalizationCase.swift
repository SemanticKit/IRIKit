import Testing
import IRIKit

struct NormalizationCase: Sendable, CustomTestStringConvertible {
    let input: String
    let normalization: IRINormalization
    let expected: String

    init(_ input: String, _ normalization: IRINormalization = .syntaxBased, expected: String) {
        self.input = input
        self.normalization = normalization
        self.expected = expected
    }

    var testDescription: String {
        "\(input) -> \(expected)"
    }
}
