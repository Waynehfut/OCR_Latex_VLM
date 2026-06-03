import AppKit
import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var status: WorkStatus = .idle
    @Published private(set) var history: [OCRHistoryItem] = []
    @Published private(set) var isWorking = false
    @Published private(set) var hotKeyError: String?
    @Published private(set) var screenCapturePermission: ScreenCapturePermissionState = .unknown
    @Published private(set) var pendingCandidate: RecognitionCandidate?

    let preferences: PreferencesStore

    private let hotKeyManager = HotKeyManager()
    private let screenCapturePermissionService = ScreenCapturePermissionService()
    private let screenCaptureService = ScreenCaptureService()
    private let ocrService = OCRService()
    private let largeModelRecognitionService = LargeModelRecognitionService()
    private let latexNormalizer = LatexNormalizer()
    private let pasteboardService = PasteboardService()
    private var toastPanel: NSPanel?

    init(preferences: PreferencesStore = PreferencesStore()) {
        self.preferences = preferences
        hotKeyManager.onHotKey = { [weak self] in
            Task { @MainActor in
                self?.captureInteractive()
            }
        }
        registerHotKey()
        refreshScreenCapturePermission()
    }

    func captureInteractive() {
        startWorkflow(source: .screenSelection)
    }

    func recognizeClipboardImage() {
        startWorkflow(source: .clipboardImage)
    }

    private func startWorkflow(source: OCRSource) {
        guard !isWorking else { return }
        Task {
            await runWorkflow(source: source)
        }
    }

    func updateHotKey(_ hotKey: HotKey) {
        preferences.hotKey = hotKey
        registerHotKey()
    }

    func resetHotKey() {
        updateHotKey(.defaultShortcut)
    }

    func copyToPasteboard(_ text: String) {
        pasteboardService.copy(text)
        status = .copied
        showToast(title: "已识别并复制到剪贴板", subtitle: truncatedPreview(text))
    }

    /// Copy a history item to pasteboard from the menu bar.
    func copyHistoryItemToPasteboard(_ item: OCRHistoryItem) {
        pasteboardService.copy(item.latex)
        showToast(title: "已复制到剪贴板", subtitle: truncatedPreview(item.latex))
    }

    func acceptPendingCandidate() {
        guard let pendingCandidate else {
            return
        }
        accept(candidate: pendingCandidate)
    }

    func discardPendingCandidate() {
        pendingCandidate = nil
        status = .idle
    }

    func updatePendingCandidateLatex(_ latex: String) {
        guard var candidate = pendingCandidate else {
            return
        }
        candidate.latex = latex
        pendingCandidate = candidate
    }

    func showDashboardWindow() {
        NSApp.setActivationPolicy(.accessory)
        NSApp.activate(ignoringOtherApps: true)
        NotificationCenter.default.post(name: AppModel.openDashboardNotification, object: nil)
    }

    static let openDashboardNotification = Notification.Name("OCRLatexOpenDashboard")

    func refreshScreenCapturePermission() {
        screenCapturePermission = screenCapturePermissionService.currentState()
    }

    func requestScreenCapturePermission() {
        let newState = screenCapturePermissionService.requestAccess()
        screenCapturePermission = newState
        if newState == .missing {
            status = .failed("请在系统设置中允许 OCR LaTeX 进行屏幕录制。")
        } else if status == .failed("请在系统设置中允许 OCR LaTeX 进行屏幕录制。") {
            status = .idle
        }
    }

    func openScreenCapturePermissionSettings() {
        screenCapturePermissionService.openSystemSettings()
    }

    private func runWorkflow(source: OCRSource) async {
        isWorking = true
        defer {
            isWorking = false
        }

        do {
            let image: NSImage
            switch source {
            case .screenSelection:
                guard ensureScreenCapturePermission() else {
                    return
                }
                status = .waitingForSelection
                image = try await screenCaptureService.captureInteractiveImage(
                    hideApp: preferences.hideAppDuringCapture
                )
            case .clipboardImage:
                image = try pasteboardService.readImage()
            }

            status = .recognizing
            let candidate = try await recognize(image: image, source: source)
            present(candidate: candidate)
        } catch CaptureError.cancelled {
            status = .cancelled
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    private func recognize(image: NSImage, source: OCRSource) async throws -> RecognitionCandidate {
        switch preferences.recognitionBackend {
        case .localVision:
            status = .recognizing
            let document = try await ocrService.recognize(
                image: image,
                usesLanguageCorrection: preferences.usesLanguageCorrection
            )
            let latex = preferences.outputWrapping.wrap(
                latexNormalizer.normalize(document.plainText)
            )
            return RecognitionCandidate(
                source: source,
                engine: .localVision,
                rawText: document.plainText,
                latex: latex,
                confidence: document.averageConfidence
            )
        case .largeModel:
            status = .callingLargeModel
            let latex = try await largeModelRecognitionService.recognize(
                image: image,
                configuration: preferences.largeModelConfiguration
            )
            return RecognitionCandidate(
                source: source,
                engine: .largeModel,
                rawText: latex,
                latex: preferences.outputWrapping.wrap(latex),
                confidence: nil
            )
        }
    }

    private func present(candidate: RecognitionCandidate) {
        if preferences.requiresAcceptance {
            pendingCandidate = candidate
            status = .awaitingAcceptance
        } else {
            accept(candidate: candidate)
        }
    }

    private func accept(candidate: RecognitionCandidate) {
        if preferences.autoCopyOutput {
            pasteboardService.copy(candidate.latex)
        }

        history.insert(
            OCRHistoryItem(
                date: Date(),
                source: candidate.source,
                rawText: candidate.rawText,
                latex: candidate.latex,
                copiedToPasteboard: preferences.autoCopyOutput,
                confidence: candidate.confidence ?? 0,
                engine: candidate.engine
            ),
            at: 0
        )

        if history.count > 20 {
            history.removeLast(history.count - 20)
        }

        pendingCandidate = nil
        status = preferences.autoCopyOutput ? .copied : .ready

        if preferences.autoCopyOutput {
            showToast(title: "已识别并复制到剪贴板", subtitle: truncatedPreview(candidate.latex))
        }
    }

    private func ensureScreenCapturePermission() -> Bool {
        status = .checkingPermission
        let newState = screenCapturePermissionService.requestAccess()
        screenCapturePermission = newState

        guard newState == .authorized else {
            status = .failed("请在系统设置中允许 OCR LaTeX 进行屏幕录制。")
            return false
        }

        return true
    }

    private func showToast(title: String, subtitle: String?) {
        toastPanel?.close()

        let toastSize = NSSize(width: 300, height: 64)
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: toastSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.animationBehavior = .utilityWindow

        let toastView = ToastView(title: title, subtitle: subtitle)
        panel.contentView = NSHostingView(rootView: toastView)

        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let margin: CGFloat = 12
            let panelRect = NSRect(
                x: screenRect.maxX - toastSize.width - margin,
                y: screenRect.maxY - toastSize.height - margin,
                width: toastSize.width,
                height: toastSize.height
            )
            panel.setFrame(panelRect, display: false)
        }

        toastPanel = panel
        panel.orderFront(nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak panel] in
            panel?.close()
        }
    }

    func truncatedPreview(_ text: String, maxLength: Int = 38) -> String {
        let firstLine = text.components(separatedBy: .newlines).first ?? text
        let cleaned = firstLine.trimmingCharacters(in: .whitespaces)
        if cleaned.count > maxLength {
            return String(cleaned.prefix(maxLength)) + "..."
        }
        return cleaned
    }

    private func registerHotKey() {
        do {
            try hotKeyManager.register(preferences.hotKey)
            hotKeyError = nil
        } catch {
            hotKeyError = error.localizedDescription
        }
    }
}

private struct ToastView: View {
    let title: String
    let subtitle: String?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.callout, weight: .semibold))
                    .foregroundStyle(.black)
                    .lineLimit(1)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.black.opacity(0.65))
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(width: 300, height: 64)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black.opacity(0.08), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
    }
}
