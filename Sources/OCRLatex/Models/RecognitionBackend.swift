import Foundation

enum RecognitionBackend: String, CaseIterable, Identifiable {
    case localVision
    case largeModel

    var id: String {
        rawValue
    }

    var label: String {
        switch self {
        case .localVision:
            "本机 OCR"
        case .largeModel:
            "大模型"
        }
    }
}

enum RecognitionEngine: String {
    case localVision = "本机 OCR"
    case largeModel = "大模型"
}

enum ImageDetailLevel: String, CaseIterable, Identifiable {
    case auto
    case low
    case high

    var id: String {
        rawValue
    }

    var label: String {
        switch self {
        case .auto:
            "自动"
        case .low:
            "低"
        case .high:
            "高"
        }
    }
}

enum LargeModelPlatform: String, CaseIterable, Identifiable {
    case openAI
    case deepSeek
    case volces
    case bailian
    case custom

    var id: String {
        rawValue
    }

    var label: String {
        switch self {
        case .openAI:
            "OpenAI"
        case .deepSeek:
            "DeepSeek"
        case .volces:
            "火山引擎"
        case .bailian:
            "阿里百炼"
        case .custom:
            "自定义"
        }
    }

    var defaultEndpoint: String {
        switch self {
        case .openAI:
            "https://api.openai.com/v1/chat/completions"
        case .deepSeek:
            "https://api.deepseek.com/v1/chat/completions"
        case .volces:
            "https://ark.cn-beijing.volces.com/api/v3/chat/completions"
        case .bailian:
            "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
        case .custom:
            ""
        }
    }

    var defaultModel: String {
        switch self {
        case .openAI:
            "gpt-4o"
        case .deepSeek:
            "deepseek-chat"
        case .volces:
            "doubao-vision-pro-32k"
        case .bailian:
            "qwen-vl-plus"
        case .custom:
            ""
        }
    }
}
