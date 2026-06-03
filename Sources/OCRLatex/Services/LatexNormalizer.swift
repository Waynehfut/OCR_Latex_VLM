import Foundation

final class LatexNormalizer {
    func normalize(_ rawText: String) -> String {
        rawText
            .components(separatedBy: .newlines)
            .map { normalizeLine($0) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    private func normalizeLine(_ line: String) -> String {
        var text = line.trimmingCharacters(in: .whitespacesAndNewlines)
        text = replaceUnicodeScripts(in: text)
        text = replaceSymbols(in: text)
        text = normalizeFunctions(in: text)
        text = normalizeSquareRoots(in: text)
        text = convertSimpleFractions(in: text)
        text = braceScripts(in: text)
        text = cleanupSpacing(in: text)
        return text
    }

    private func replaceSymbols(in text: String) -> String {
        symbolReplacements.reduce(text) { result, replacement in
            result.replacingOccurrences(of: replacement.source, with: replacement.target)
        }
    }

    private func replaceUnicodeScripts(in text: String) -> String {
        var result = ""
        var superscriptBuffer = ""
        var subscriptBuffer = ""

        func flushSuperscript() {
            guard !superscriptBuffer.isEmpty else {
                return
            }
            result += "^{\(superscriptBuffer)}"
            superscriptBuffer = ""
        }

        func flushSubscript() {
            guard !subscriptBuffer.isEmpty else {
                return
            }
            result += "_{\(subscriptBuffer)}"
            subscriptBuffer = ""
        }

        for character in text {
            if let mapped = superscriptCharacters[character] {
                flushSubscript()
                superscriptBuffer += mapped
            } else if let mapped = subscriptCharacters[character] {
                flushSuperscript()
                subscriptBuffer += mapped
            } else {
                flushSuperscript()
                flushSubscript()
                result.append(character)
            }
        }

        flushSuperscript()
        flushSubscript()
        return result
    }

    private func normalizeFunctions(in text: String) -> String {
        functionNames.reduce(text) { result, name in
            result.replacingOccurrences(
                of: #"(?<!\\)\b\#(name)\b"#,
                with: #"\\\#(name)"#,
                options: .regularExpression
            )
        }
    }

    private func normalizeSquareRoots(in text: String) -> String {
        var result = text.replacingOccurrences(
            of: #"\\sqrt\s*\(([^)]+)\)"#,
            with: #"\\sqrt{$1}"#,
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: #"\\sqrt\s+([A-Za-z0-9]+)"#,
            with: #"\\sqrt{$1}"#,
            options: .regularExpression
        )
        return result
    }

    private func convertSimpleFractions(in text: String) -> String {
        text.replacingOccurrences(
            of: #"\b([A-Za-z0-9]+)\s*/\s*([A-Za-z0-9]+)\b"#,
            with: #"\\frac{$1}{$2}"#,
            options: .regularExpression
        )
    }

    private func braceScripts(in text: String) -> String {
        var result = text.replacingOccurrences(
            of: #"\^\s*([A-Za-z0-9]+)"#,
            with: #"^{$1}"#,
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: #"_\s*([A-Za-z0-9]+)"#,
            with: #"_{$1}"#,
            options: .regularExpression
        )
        return result
    }

    private func cleanupSpacing(in text: String) -> String {
        var result = text.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
        )
        let tightOperators = [
            (" {", "{"),
            ("} ", "}"),
            ("^ {", "^{"),
            ("_ {", "_{")
        ]
        for replacement in tightOperators {
            result = result.replacingOccurrences(of: replacement.0, with: replacement.1)
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private let functionNames = [
        "sin",
        "cos",
        "tan",
        "cot",
        "sec",
        "csc",
        "log",
        "ln",
        "exp",
        "lim",
        "max",
        "min"
    ]

    private let symbolReplacements: [(source: String, target: String)] = [
        ("−", "-"),
        ("–", "-"),
        ("—", "-"),
        ("×", " \\times "),
        ("÷", " \\div "),
        ("·", " \\cdot "),
        ("•", " \\cdot "),
        ("±", " \\pm "),
        ("∓", " \\mp "),
        ("≤", " \\le "),
        ("≥", " \\ge "),
        ("≠", " \\ne "),
        ("≈", " \\approx "),
        ("≃", " \\simeq "),
        ("≡", " \\equiv "),
        ("∞", " \\infty "),
        ("∑", " \\sum "),
        ("∏", " \\prod "),
        ("∫", " \\int "),
        ("√", "\\sqrt "),
        ("∂", "\\partial "),
        ("∇", "\\nabla "),
        ("∈", " \\in "),
        ("∉", " \\notin "),
        ("⊂", " \\subset "),
        ("⊆", " \\subseteq "),
        ("⊃", " \\supset "),
        ("⊇", " \\supseteq "),
        ("∪", " \\cup "),
        ("∩", " \\cap "),
        ("→", " \\to "),
        ("←", " \\leftarrow "),
        ("↔", " \\leftrightarrow "),
        ("⇒", " \\Rightarrow "),
        ("⇔", " \\Leftrightarrow "),
        ("α", "\\alpha"),
        ("β", "\\beta"),
        ("γ", "\\gamma"),
        ("δ", "\\delta"),
        ("ε", "\\epsilon"),
        ("ζ", "\\zeta"),
        ("η", "\\eta"),
        ("θ", "\\theta"),
        ("ι", "\\iota"),
        ("κ", "\\kappa"),
        ("λ", "\\lambda"),
        ("μ", "\\mu"),
        ("ν", "\\nu"),
        ("ξ", "\\xi"),
        ("π", "\\pi"),
        ("ρ", "\\rho"),
        ("σ", "\\sigma"),
        ("τ", "\\tau"),
        ("υ", "\\upsilon"),
        ("φ", "\\phi"),
        ("χ", "\\chi"),
        ("ψ", "\\psi"),
        ("ω", "\\omega"),
        ("Γ", "\\Gamma"),
        ("Δ", "\\Delta"),
        ("Θ", "\\Theta"),
        ("Λ", "\\Lambda"),
        ("Ξ", "\\Xi"),
        ("Π", "\\Pi"),
        ("Σ", "\\Sigma"),
        ("Φ", "\\Phi"),
        ("Ψ", "\\Psi"),
        ("Ω", "\\Omega")
    ]

    private let superscriptCharacters: [Character: String] = [
        "⁰": "0",
        "¹": "1",
        "²": "2",
        "³": "3",
        "⁴": "4",
        "⁵": "5",
        "⁶": "6",
        "⁷": "7",
        "⁸": "8",
        "⁹": "9",
        "⁺": "+",
        "⁻": "-",
        "⁽": "(",
        "⁾": ")",
        "ⁿ": "n"
    ]

    private let subscriptCharacters: [Character: String] = [
        "₀": "0",
        "₁": "1",
        "₂": "2",
        "₃": "3",
        "₄": "4",
        "₅": "5",
        "₆": "6",
        "₇": "7",
        "₈": "8",
        "₉": "9",
        "₊": "+",
        "₋": "-",
        "₍": "(",
        "₎": ")",
        "ₙ": "n"
    ]
}
