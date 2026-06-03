import Foundation

enum OutputWrapping: String, CaseIterable, Identifiable {
    case plain
    case inline
    case display

    var id: String {
        rawValue
    }

    var label: String {
        switch self {
        case .plain:
            "纯 LaTeX"
        case .inline:
            "行内公式"
        case .display:
            "展示公式"
        }
    }

    func wrap(_ latex: String) -> String {
        switch self {
        case .plain:
            latex
        case .inline:
            "\\(\(latex)\\)"
        case .display:
            "\\[\n\(latex)\n\\]"
        }
    }
}
