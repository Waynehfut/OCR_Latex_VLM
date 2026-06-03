import AppKit
import Foundation

enum PasteboardError: LocalizedError {
    case noImage

    var errorDescription: String? {
        switch self {
        case .noImage:
            "剪贴板里没有可识别的图片。"
        }
    }
}

@MainActor
final class PasteboardService {
    func copy(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    func readImage() throws -> NSImage {
        let pasteboard = NSPasteboard.general
        if let image = NSImage(pasteboard: pasteboard) {
            return image
        }

        if let data = pasteboard.data(forType: .tiff),
           let image = NSImage(data: data) {
            return image
        }

        throw PasteboardError.noImage
    }
}
