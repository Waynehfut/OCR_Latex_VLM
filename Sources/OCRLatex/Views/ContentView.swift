import SwiftUI

struct ContentView: View {
    @ObservedObject var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(model: model)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ActionPanelView(model: model)
                    PermissionPanelView(model: model)
                    CandidatePanelView(model: model)
                    StatusPanelView(model: model)
                    PreferencesPanelView(model: model)
                    AboutPanelView()
                    HistoryPanelView(model: model)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(for: AppModel.openDashboardNotification)
        ) { _ in
            openWindow(id: "dashboard")
        }
    }
}

private struct HeaderView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "function")
                .font(.title2)
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("OCR LaTeX")
                    .font(.title2.weight(.semibold))
                Text(model.preferences.hotKey.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                model.captureInteractive()
            } label: {
                Label("截取公式", systemImage: "viewfinder")
            }
            .disabled(model.isWorking)
            .keyboardShortcut("r", modifiers: [.command])
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}

private struct ActionPanelView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        HStack(spacing: 12) {
            Button {
                model.captureInteractive()
            } label: {
                Label("区域 OCR", systemImage: "viewfinder")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .disabled(model.isWorking)

            Button {
                model.recognizeClipboardImage()
            } label: {
                Label("剪贴板 OCR", systemImage: "doc.on.clipboard")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .disabled(model.isWorking)
        }
    }
}

private struct StatusPanelView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        GroupBox {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: model.status.systemImageName)
                    .font(.title3)
                    .foregroundStyle(statusColor)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(model.status.title)
                        .font(.headline)
                    Text(model.status.detail)
                        .foregroundStyle(.secondary)

                    if let hotKeyError = model.hotKeyError {
                        Text(hotKeyError)
                            .foregroundStyle(.orange)
                    }
                }

                Spacer()

                if model.isWorking {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var statusColor: Color {
        switch model.status {
        case .failed:
            .red
        case .copied, .ready:
            .green
        case .cancelled:
            .secondary
        case .checkingPermission, .waitingForSelection, .recognizing, .callingLargeModel, .awaitingAcceptance:
            .accentColor
        case .idle:
            .secondary
        }
    }
}

private struct CandidatePanelView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        if let candidate = model.pendingCandidate {
            GroupBox("候选结果") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label(candidate.engine.rawValue, systemImage: "sparkles")
                            .foregroundStyle(.secondary)
                        Text(candidate.source.rawValue)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            model.copyToPasteboard(candidate.latex)
                        } label: {
                            Label("复制", systemImage: "doc.on.doc")
                        }
                        Button {
                            model.discardPendingCandidate()
                        } label: {
                            Label("丢弃", systemImage: "xmark.circle")
                        }
                        Button {
                            model.acceptPendingCandidate()
                        } label: {
                            Label("接受", systemImage: "checkmark.circle")
                        }
                        .keyboardShortcut(.defaultAction)
                    }
                    .font(.caption)

                    TextEditor(
                        text: Binding(
                            get: { candidate.latex },
                            set: { model.updatePendingCandidateLatex($0) }
                        )
                    )
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 92)
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.25))
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

private struct AboutPanelView: View {
    var body: some View {
        GroupBox("关于") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "person.crop.circle")
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 6) {
                        AboutRow(title: "作者", value: "Waynehfut")
                        AboutLinkRow(
                            title: "仓库地址",
                            label: "github.com/Waynehfut/OCR_Latex_VLM",
                            url: URL(string: "https://github.com/Waynehfut/OCR_Latex_VLM")!
                        )
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

private struct AboutRow: View {
    var title: String
    var value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title)
                .foregroundStyle(.secondary)
                .frame(width: 96, alignment: .leading)
            Text(value)
                .textSelection(.enabled)
        }
    }
}

private struct AboutLinkRow: View {
    var title: String
    var label: String
    var url: URL

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title)
                .foregroundStyle(.secondary)
                .frame(width: 96, alignment: .leading)
            Link(label, destination: url)
        }
    }
}

private struct PermissionPanelView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        if model.screenCapturePermission != .authorized {
            GroupBox("权限") {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: model.screenCapturePermission.systemImageName)
                        .font(.title3)
                        .foregroundStyle(.orange)
                        .frame(width: 24)

                    Text(model.screenCapturePermission.title)
                        .font(.headline)

                    Spacer()

                    Button {
                        model.requestScreenCapturePermission()
                    } label: {
                        Label("请求授权", systemImage: "checkmark.shield")
                    }

                    Button {
                        model.openScreenCapturePermissionSettings()
                    } label: {
                        Label("系统设置", systemImage: "gearshape")
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

private struct HistoryPanelView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        GroupBox("最近结果") {
            if model.history.isEmpty {
                Text("暂无结果")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    ForEach(model.history) { item in
                        HistoryRowView(model: model, item: item)
                        if item.id != model.history.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

private struct HistoryRowView: View {
    @ObservedObject var model: AppModel
    var item: OCRHistoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(item.source.rawValue, systemImage: "text.viewfinder")
                    .foregroundStyle(.secondary)
                Text(item.engine.rawValue)
                    .foregroundStyle(.secondary)
                Text(DateFormatting.historyFormatter.string(from: item.date))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.0f%%", item.confidence * 100))
                    .foregroundStyle(.secondary)
                Button {
                    model.copyToPasteboard(item.latex)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .help("复制")
            }
            .font(.caption)

            Text(item.latex)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}
