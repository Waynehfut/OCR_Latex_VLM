import Foundation

final class PreferencesStore: ObservableObject {
    @Published var hotKey: HotKey {
        didSet {
            saveHotKey()
        }
    }

    @Published var outputWrapping: OutputWrapping {
        didSet {
            defaults.set(outputWrapping.rawValue, forKey: Keys.outputWrapping)
        }
    }

    @Published var autoCopyOutput: Bool {
        didSet {
            defaults.set(autoCopyOutput, forKey: Keys.autoCopyOutput)
        }
    }

    @Published var hideAppDuringCapture: Bool {
        didSet {
            defaults.set(hideAppDuringCapture, forKey: Keys.hideAppDuringCapture)
        }
    }

    @Published var usesLanguageCorrection: Bool {
        didSet {
            defaults.set(usesLanguageCorrection, forKey: Keys.usesLanguageCorrection)
        }
    }

    @Published var recognitionBackend: RecognitionBackend {
        didSet {
            defaults.set(recognitionBackend.rawValue, forKey: Keys.recognitionBackend)
        }
    }

    @Published var requiresAcceptance: Bool {
        didSet {
            defaults.set(requiresAcceptance, forKey: Keys.requiresAcceptance)
        }
    }

    @Published var largeModelEndpoint: String {
        didSet {
            defaults.set(largeModelEndpoint, forKey: Keys.largeModelEndpoint)
        }
    }

    @Published var largeModelAPIKey: String {
        didSet {
            keychain.saveAPIKey(largeModelAPIKey)
        }
    }

    @Published var largeModelName: String {
        didSet {
            defaults.set(largeModelName, forKey: Keys.largeModelName)
        }
    }

    @Published var largeModelImageDetail: ImageDetailLevel {
        didSet {
            defaults.set(largeModelImageDetail.rawValue, forKey: Keys.largeModelImageDetail)
        }
    }

    @Published var largeModelPrompt: String {
        didSet {
            defaults.set(largeModelPrompt, forKey: Keys.largeModelPrompt)
        }
    }

    @Published var largeModelPlatform: LargeModelPlatform {
        didSet {
            defaults.set(largeModelPlatform.rawValue, forKey: Keys.largeModelPlatform)
        }
    }

    private let defaults: UserDefaults
    private let keychain = KeychainService()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let data = defaults.data(forKey: Keys.hotKey),
           let hotKey = try? JSONDecoder().decode(HotKey.self, from: data) {
            self.hotKey = hotKey
        } else {
            self.hotKey = .defaultShortcut
        }

        let wrappingValue = defaults.string(forKey: Keys.outputWrapping)
        self.outputWrapping = OutputWrapping(rawValue: wrappingValue ?? "") ?? .plain

        if defaults.object(forKey: Keys.autoCopyOutput) == nil {
            self.autoCopyOutput = true
        } else {
            self.autoCopyOutput = defaults.bool(forKey: Keys.autoCopyOutput)
        }

        if defaults.object(forKey: Keys.hideAppDuringCapture) == nil {
            self.hideAppDuringCapture = true
        } else {
            self.hideAppDuringCapture = defaults.bool(forKey: Keys.hideAppDuringCapture)
        }

        if defaults.object(forKey: Keys.usesLanguageCorrection) == nil {
            self.usesLanguageCorrection = false
        } else {
            self.usesLanguageCorrection = defaults.bool(forKey: Keys.usesLanguageCorrection)
        }

        let backendValue = defaults.string(forKey: Keys.recognitionBackend)
        self.recognitionBackend = RecognitionBackend(rawValue: backendValue ?? "") ?? .localVision

        if defaults.object(forKey: Keys.requiresAcceptance) == nil {
            self.requiresAcceptance = true
        } else {
            self.requiresAcceptance = defaults.bool(forKey: Keys.requiresAcceptance)
        }

        self.largeModelEndpoint = defaults.string(forKey: Keys.largeModelEndpoint)
            ?? "https://api.openai.com/v1/chat/completions"
        self.largeModelAPIKey = keychain.readAPIKey()
        self.largeModelName = defaults.string(forKey: Keys.largeModelName) ?? "gpt-4o"

        let platformValue = defaults.string(forKey: Keys.largeModelPlatform)
        self.largeModelPlatform = LargeModelPlatform(rawValue: platformValue ?? "") ?? .openAI

        let detailValue = defaults.string(forKey: Keys.largeModelImageDetail)
        self.largeModelImageDetail = ImageDetailLevel(rawValue: detailValue ?? "") ?? .high

        self.largeModelPrompt = defaults.string(forKey: Keys.largeModelPrompt)
            ?? Self.defaultLargeModelPrompt
    }

    var largeModelConfiguration: LargeModelConfiguration {
        LargeModelConfiguration(
            endpoint: largeModelEndpoint,
            apiKey: largeModelAPIKey,
            model: largeModelName,
            imageDetail: largeModelImageDetail,
            prompt: largeModelPrompt
        )
    }

    private func saveHotKey() {
        guard let data = try? JSONEncoder().encode(hotKey) else {
            return
        }
        defaults.set(data, forKey: Keys.hotKey)
    }

    private enum Keys {
        static let hotKey = "hotKey"
        static let outputWrapping = "outputWrapping"
        static let autoCopyOutput = "autoCopyOutput"
        static let hideAppDuringCapture = "hideAppDuringCapture"
        static let usesLanguageCorrection = "usesLanguageCorrection"
        static let recognitionBackend = "recognitionBackend"
        static let requiresAcceptance = "requiresAcceptance"
        static let largeModelEndpoint = "largeModelEndpoint"
        static let largeModelName = "largeModelName"
        static let largeModelImageDetail = "largeModelImageDetail"
        static let largeModelPrompt = "largeModelPrompt"
        static let largeModelPlatform = "largeModelPlatform"
    }

    private static let defaultLargeModelPrompt = """
    You are a math OCR engine. Convert the formula in the image into LaTeX.
    Return only the LaTeX expression. Do not include explanations, Markdown fences, surrounding prose, or confidence notes.
    Preserve line breaks for multi-line formulas.
    """
}
