import AppKit
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button {
            model.captureInteractive()
        } label: {
            Label("截取公式", systemImage: "viewfinder")
        }
        .disabled(model.isWorking)

        Button {
            model.recognizeClipboardImage()
        } label: {
            Label("识别剪贴板图片", systemImage: "doc.on.clipboard")
        }
        .disabled(model.isWorking)

        Divider()

        Label(model.status.title, systemImage: model.status.systemImageName)

        if model.pendingCandidate != nil {
            Button {
                model.acceptPendingCandidate()
            } label: {
                Label("接受结果", systemImage: "checkmark.circle")
            }

            Button {
                model.discardPendingCandidate()
            } label: {
                Label("丢弃结果", systemImage: "xmark.circle")
            }
        }

        if let hotKeyError = model.hotKeyError {
            Label(hotKeyError, systemImage: "exclamationmark.triangle")
        }

        if model.screenCapturePermission == .missing {
            Button {
                model.openScreenCapturePermissionSettings()
            } label: {
                Label("打开屏幕录制设置", systemImage: "lock.open")
            }
        }

        if !model.history.isEmpty {
            Divider()

            Text("最近结果 — \(model.history.count) 条")
                .font(.caption)

            ForEach(model.history.prefix(5)) { item in
                Button {
                    model.copyHistoryItemToPasteboard(item)
                } label: {
                    Label(
                        truncatedMenuLabel(item.latex),
                        systemImage: item.engine == .largeModel
                            ? "sparkles"
                            : "text.viewfinder"
                    )
                }
            }

            Button {
                model.showDashboardWindow()
            } label: {
                Label("查看全部...", systemImage: "ellipsis")
            }
        }

        Divider()

        Button {
            openWindow(id: "dashboard")
            model.showDashboardWindow()
        } label: {
            Label("打开控制面板", systemImage: "macwindow")
        }

        if #available(macOS 14.0, *) {
            SettingsLink {
                Label("偏好设置", systemImage: "gearshape")
            }
        } else {
            Button {
                model.openPreferencesWindow()
            } label: {
                Label("偏好设置", systemImage: "gearshape")
            }
        }

        Divider()

        Button {
            NSApp.terminate(nil)
        } label: {
            Label("退出", systemImage: "power")
        }
    }

    private func truncatedMenuLabel(_ text: String) -> String {
        let firstLine = text.components(separatedBy: .newlines).first ?? text
        let cleaned = firstLine.trimmingCharacters(in: .whitespaces)
        if cleaned.count > 50 {
            return String(cleaned.prefix(50)) + "..."
        }
        return cleaned
    }
}
