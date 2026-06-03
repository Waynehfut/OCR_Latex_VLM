import AppKit
import Foundation

enum CaptureError: LocalizedError {
    case cancelled
    case processFailed(Int32)
    case launchFailed(Error)
    case noImageInPasteboard

    var errorDescription: String? {
        switch self {
        case .cancelled:
            "截图已取消。"
        case .processFailed(let status):
            "系统截图工具退出异常（状态 \(status)）。"
        case .launchFailed(let error):
            "无法启动系统截图工具：\(error.localizedDescription)"
        case .noImageInPasteboard:
            "没有从剪贴板读取到截图。"
        }
    }
}

@MainActor
final class ScreenCaptureService {
    func captureInteractiveImage(hideApp: Bool) async throws -> NSImage {
        let wasHidden = NSApp.isHidden
        if hideApp {
            NSApp.hide(nil)
            try? await Task.sleep(nanoseconds: 180_000_000)
        }

        defer {
            if hideApp && !wasHidden {
                NSApp.unhide(nil)
            }
        }

        let previousChangeCount = NSPasteboard.general.changeCount

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
                process.arguments = ["-i", "-c"]

                do {
                    try process.run()
                    process.waitUntilExit()
                } catch {
                    continuation.resume(throwing: CaptureError.launchFailed(error))
                    return
                }

                let terminationStatus = process.terminationStatus
                DispatchQueue.main.async {
                    guard terminationStatus == 0 else {
                        if terminationStatus == 1 {
                            continuation.resume(throwing: CaptureError.cancelled)
                        } else {
                            continuation.resume(throwing: CaptureError.processFailed(terminationStatus))
                        }
                        return
                    }

                    let pasteboard = NSPasteboard.general
                    guard pasteboard.changeCount != previousChangeCount,
                          let image = NSImage(pasteboard: pasteboard) else {
                        continuation.resume(throwing: CaptureError.noImageInPasteboard)
                        return
                    }

                    continuation.resume(returning: image)
                }
            }
        }
    }
}
