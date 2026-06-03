import AppKit
import SwiftUI

struct PreferencesPanelView: View {
    @ObservedObject var model: AppModel
    @ObservedObject private var preferences: PreferencesStore

    init(model: AppModel) {
        self.model = model
        _preferences = ObservedObject(wrappedValue: model.preferences)
    }

    var body: some View {
        GroupBox("设置") {
            VStack(alignment: .leading, spacing: 14) {
                ShortcutRecorderView(model: model)

                Divider()

                Picker("输出格式", selection: $preferences.outputWrapping) {
                    ForEach(OutputWrapping.allCases) { wrapping in
                        Text(wrapping.label).tag(wrapping)
                    }
                }
                .pickerStyle(.segmented)

                Picker("识别后端", selection: $preferences.recognitionBackend) {
                    ForEach(RecognitionBackend.allCases) { backend in
                        Text(backend.label).tag(backend)
                    }
                }
                .pickerStyle(.segmented)

                Toggle("识别后自动复制", isOn: $preferences.autoCopyOutput)
                Toggle("识别后等待确认", isOn: $preferences.requiresAcceptance)
                Toggle("截图时隐藏本应用", isOn: $preferences.hideAppDuringCapture)
                Toggle("使用语言纠错", isOn: $preferences.usesLanguageCorrection)

                if preferences.recognitionBackend == .largeModel {
                    Divider()
                    LargeModelSettingsView(preferences: preferences)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

private struct LargeModelSettingsView: View {
    @ObservedObject var preferences: PreferencesStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("平台", selection: $preferences.largeModelPlatform) {
                ForEach(LargeModelPlatform.allCases) { platform in
                    Text(platform.label).tag(platform)
                }
            }
            .onChange(of: preferences.largeModelPlatform) { newPlatform in
                guard newPlatform != .custom else { return }
                preferences.largeModelEndpoint = newPlatform.defaultEndpoint
                preferences.largeModelName = newPlatform.defaultModel
            }

            TextField("接口地址", text: $preferences.largeModelEndpoint)
                .textFieldStyle(.roundedBorder)

            SecureField("API Key", text: $preferences.largeModelAPIKey)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 12) {
                TextField("模型名称", text: $preferences.largeModelName)
                    .textFieldStyle(.roundedBorder)

                Picker("图像精度", selection: $preferences.largeModelImageDetail) {
                    ForEach(ImageDetailLevel.allCases) { detail in
                        Text(detail.label).tag(detail)
                    }
                }
                .frame(width: 160)
            }

            TextEditor(text: $preferences.largeModelPrompt)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 84)
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.25))
                }
        }
    }
}

private struct ShortcutRecorderView: View {
    @ObservedObject var model: AppModel
    @ObservedObject private var preferences: PreferencesStore
    @StateObject private var recorder = ShortcutRecorder()

    init(model: AppModel) {
        self.model = model
        _preferences = ObservedObject(wrappedValue: model.preferences)
    }

    var body: some View {
        HStack {
            Text("全局快捷键")

            Spacer()

            Button {
                recorder.start { hotKey in
                    model.updateHotKey(hotKey)
                }
            } label: {
                Text(recorder.isRecording ? "按下组合键" : preferences.hotKey.displayName)
                    .font(.system(.body, design: .monospaced))
                    .frame(minWidth: 116)
            }

            Button {
                model.resetHotKey()
            } label: {
                Image(systemName: "arrow.counterclockwise")
            }
            .help("恢复默认")
        }
        .onDisappear {
            recorder.stop()
        }
    }
}

@MainActor
private final class ShortcutRecorder: ObservableObject {
    @Published var isRecording = false

    private var monitor: Any?

    func start(onCapture: @escaping (HotKey) -> Void) {
        stop()
        isRecording = true

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else {
                return event
            }

            if event.keyCode == 53 {
                self.stop()
                return nil
            }

            let modifiers = HotKey.carbonModifiers(from: event.modifierFlags)
            guard modifiers != 0 else {
                NSSound.beep()
                return nil
            }

            onCapture(
                HotKey(
                    keyCode: UInt32(event.keyCode),
                    modifiers: modifiers
                )
            )
            self.stop()
            return nil
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        isRecording = false
    }
}
