import AppKit
import Foundation

struct LargeModelConfiguration {
    var endpoint: String
    var apiKey: String
    var model: String
    var imageDetail: ImageDetailLevel
    var prompt: String
}

enum LargeModelRecognitionError: LocalizedError {
    case incompleteConfiguration
    case invalidEndpoint
    case imageEncodingFailed
    case invalidResponse
    case requestFailed(Int, String)

    var errorDescription: String? {
        switch self {
        case .incompleteConfiguration:
            "请先填写大模型地址、API Key 和模型名称。"
        case .invalidEndpoint:
            "大模型接口地址无效。"
        case .imageEncodingFailed:
            "无法把图片编码为模型输入。"
        case .invalidResponse:
            "大模型返回结果无法解析。"
        case .requestFailed(let statusCode, let message):
            "大模型请求失败（\(statusCode)）：\(message)"
        }
    }
}

final class LargeModelRecognitionService {
    func recognize(image: NSImage, configuration: LargeModelConfiguration) async throws -> String {
        let endpoint = configuration.endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        let apiKey = configuration.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let model = configuration.model.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !endpoint.isEmpty, !apiKey.isEmpty, !model.isEmpty else {
            throw LargeModelRecognitionError.incompleteConfiguration
        }

        guard let url = URL(string: endpoint) else {
            throw LargeModelRecognitionError.invalidEndpoint
        }

        guard let imageDataURL = image.pngDataURL() else {
            throw LargeModelRecognitionError.imageEncodingFailed
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 90

        let body: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": configuration.prompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": imageDataURL,
                                "detail": configuration.imageDetail.rawValue
                            ]
                        ]
                    ]
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LargeModelRecognitionError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? ""
            throw LargeModelRecognitionError.requestFailed(httpResponse.statusCode, message)
        }

        return try parseLatex(from: data)
    }

    private func parseLatex(from data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw LargeModelRecognitionError.invalidResponse
        }

        return cleaned(content)
    }

    private func cleaned(_ text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if result.hasPrefix("```") {
            result = result.replacingOccurrences(
                of: #"^```(?:latex|tex)?\s*"#,
                with: "",
                options: .regularExpression
            )
            result = result.replacingOccurrences(
                of: #"\s*```$"#,
                with: "",
                options: .regularExpression
            )
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension NSImage {
    func pngDataURL() -> String? {
        guard let cgImage = cgImage() else {
            return nil
        }

        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }

        return "data:image/png;base64,\(data.base64EncodedString())"
    }
}
