import AppKit
import Foundation
import Vision

enum OCRError: LocalizedError {
    case imageConversionFailed
    case noText

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            "无法把图片转换为 OCR 输入。"
        case .noText:
            "没有识别到文本。"
        }
    }
}

final class OCRService {
    func recognize(image: NSImage, usesLanguageCorrection: Bool) async throws -> OCRDocument {
        guard let cgImage = image.cgImageForOCR() else {
            throw OCRError.imageConversionFailed
        }

        return try await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = usesLanguageCorrection
            request.minimumTextHeight = 0.01

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])

            let observations = request.results ?? []
            let lines = observations.compactMap { observation -> RecognizedTextLine? in
                guard let candidate = observation.topCandidates(1).first else {
                    return nil
                }

                let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else {
                    return nil
                }

                return RecognizedTextLine(
                    text: text,
                    confidence: candidate.confidence,
                    boundingBox: observation.boundingBox
                )
            }

            let sortedLines = Self.sortReadingOrder(lines)
            guard !sortedLines.isEmpty else {
                throw OCRError.noText
            }

            return OCRDocument(lines: sortedLines)
        }.value
    }

    private static func sortReadingOrder(_ lines: [RecognizedTextLine]) -> [RecognizedTextLine] {
        lines.sorted { left, right in
            let deltaY = abs(left.boundingBox.midY - right.boundingBox.midY)
            if deltaY > 0.03 {
                return left.boundingBox.midY > right.boundingBox.midY
            }
            return left.boundingBox.minX < right.boundingBox.minX
        }
    }
}

private extension NSImage {
    func cgImageForOCR() -> CGImage? {
        var proposedRect = CGRect(origin: .zero, size: size)
        if let image = cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) {
            return image
        }

        guard let tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffRepresentation) else {
            return nil
        }
        return bitmap.cgImage
    }
}
