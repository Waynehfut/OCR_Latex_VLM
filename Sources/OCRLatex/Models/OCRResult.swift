import CoreGraphics
import Foundation

struct RecognizedTextLine: Identifiable {
    let id = UUID()
    var text: String
    var confidence: Float
    var boundingBox: CGRect
}

struct OCRDocument {
    var lines: [RecognizedTextLine]

    var plainText: String {
        lines.map(\.text).joined(separator: "\n")
    }

    var averageConfidence: Float {
        guard !lines.isEmpty else {
            return 0
        }
        let total = lines.reduce(Float(0)) { $0 + $1.confidence }
        return total / Float(lines.count)
    }
}

struct OCRHistoryItem: Identifiable {
    let id = UUID()
    var date: Date
    var source: OCRSource
    var rawText: String
    var latex: String
    var copiedToPasteboard: Bool
    var confidence: Float
    var engine: RecognitionBackend
}

enum OCRSource: String {
    case screenSelection = "区域截图"
    case clipboardImage = "剪贴板图片"
}
