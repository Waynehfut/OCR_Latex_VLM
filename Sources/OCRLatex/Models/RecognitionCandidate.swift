import Foundation

struct RecognitionCandidate: Identifiable {
    let id = UUID()
    var source: OCRSource
    var engine: RecognitionEngine
    var rawText: String
    var latex: String
    var confidence: Float?
}
