extension IRITemplate: Equatable {
    /// Returns whether two templates contain the same Unicode scalar sequence.
    public static func == (lhs: IRITemplate, rhs: IRITemplate) -> Bool {
        lhs.rawValue.unicodeScalars.elementsEqual(rhs.rawValue.unicodeScalars)
    }
}
