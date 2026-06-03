import AppKit

extension NSImage {
    /// Extracts a CGImage from the receiver, falling back to TIFF representation
    /// when the primary path returns nil.
    func cgImage() -> CGImage? {
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
