/// Punycode decoding and encoding from RFC 3492, used to compare IDN host
/// labels with their ASCII Compatible Encoding during scheme-based
/// normalization. Encoding checks that a decoded label round-trips to the
/// same ACE label (IDNA ToUnicode, RFC 3490 section 4.2).
enum Punycode {
    private static let base = 36
    private static let tMin = 1
    private static let tMax = 26
    private static let skew = 38
    private static let damp = 700
    private static let initialBias = 72
    private static let initialN = 128

    /// Decodes a Punycode string (the part of an ACE label after `xn--`).
    ///
    /// Returns `nil` when the input is not valid Punycode.
    static func decode(_ input: String) -> String? {
        let scalars = Array(input.unicodeScalars)
        guard scalars.allSatisfy(\.isASCII) else {
            return nil
        }

        var output: [Unicode.Scalar] = []
        var position = 0
        if let delimiter = scalars.lastIndex(of: "-") {
            output = Array(scalars[..<delimiter])
            position = delimiter + 1
        }

        var n = initialN
        var i = 0
        var bias = initialBias

        while position < scalars.count {
            let oldI = i
            var weight = 1
            var k = base
            while true {
                guard position < scalars.count,
                    let digit = digitValue(scalars[position])
                else {
                    return nil
                }
                position += 1

                let (product, productOverflow) = digit.multipliedReportingOverflow(by: weight)
                let (sum, sumOverflow) = i.addingReportingOverflow(product)
                guard !productOverflow, !sumOverflow else {
                    return nil
                }
                i = sum

                let threshold = k <= bias ? tMin : (k >= bias + tMax ? tMax : k - bias)
                if digit < threshold {
                    break
                }

                let (nextWeight, weightOverflow) = weight.multipliedReportingOverflow(by: base - threshold)
                guard !weightOverflow else {
                    return nil
                }
                weight = nextWeight
                k += base
            }

            let length = output.count + 1
            bias = adapt(delta: i - oldI, numberOfPoints: length, isFirstTime: oldI == 0)
            let (nextN, nOverflow) = n.addingReportingOverflow(i / length)
            guard !nOverflow else {
                return nil
            }
            n = nextN
            i %= length

            guard let scalar = Unicode.Scalar(UInt32(clamping: n)), n <= 0x10FFFF else {
                return nil
            }
            output.insert(scalar, at: i)
            i += 1
        }

        var result = ""
        result.unicodeScalars.append(contentsOf: output)
        return result
    }

    /// Encodes a Unicode label as Punycode (without the `xn--` prefix).
    ///
    /// Returns `nil` when the encoding overflows.
    static func encode(_ input: String) -> String? {
        let scalars = Array(input.unicodeScalars)
        var output = String.UnicodeScalarView(scalars.filter(\.isASCII))
        let basicCount = output.count
        var handled = basicCount
        if basicCount > 0 {
            output.append("-")
        }

        var n = initialN
        var delta = 0
        var bias = initialBias

        while handled < scalars.count {
            guard let m = scalars.lazy.map({ Int($0.value) }).filter({ $0 >= n }).min() else {
                return nil
            }
            let (increment, incrementOverflow) = (m - n).multipliedReportingOverflow(by: handled + 1)
            let (nextDelta, deltaOverflow) = delta.addingReportingOverflow(increment)
            guard !incrementOverflow, !deltaOverflow else {
                return nil
            }
            delta = nextDelta
            n = m

            for scalar in scalars {
                let value = Int(scalar.value)
                if value < n {
                    delta += 1
                }
                guard value == n else {
                    continue
                }

                var q = delta
                var k = base
                while true {
                    let threshold = k <= bias ? tMin : (k >= bias + tMax ? tMax : k - bias)
                    if q < threshold {
                        break
                    }
                    output.append(digitScalar(threshold + (q - threshold) % (base - threshold)))
                    q = (q - threshold) / (base - threshold)
                    k += base
                }
                output.append(digitScalar(q))
                bias = adapt(delta: delta, numberOfPoints: handled + 1, isFirstTime: handled == basicCount)
                delta = 0
                handled += 1
            }

            delta += 1
            n += 1
        }

        return String(output)
    }

    private static func digitScalar(_ digit: Int) -> Unicode.Scalar {
        Unicode.Scalar(UInt8(digit < 26 ? 0x61 + digit : 0x30 + digit - 26))
    }

    private static func adapt(delta: Int, numberOfPoints: Int, isFirstTime: Bool) -> Int {
        var delta = isFirstTime ? delta / damp : delta / 2
        delta += delta / numberOfPoints
        var k = 0
        while delta > ((base - tMin) * tMax) / 2 {
            delta /= base - tMin
            k += base
        }
        return k + (base - tMin + 1) * delta / (delta + skew)
    }

    private static func digitValue(_ scalar: Unicode.Scalar) -> Int? {
        switch scalar.value {
        case 0x30...0x39:
            Int(scalar.value - 0x30) + 26
        case 0x41...0x5A:
            Int(scalar.value - 0x41)
        case 0x61...0x7A:
            Int(scalar.value - 0x61)
        default:
            nil
        }
    }
}
