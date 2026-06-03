import Foundation
import Security

final class KeychainService {
    private let service = "OCRLatex"
    private let account = "LargeModelAPIKey"

    func readAPIKey() -> String {
        var query: [String: Any] = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return ""
        }

        return value
    }

    func saveAPIKey(_ apiKey: String) {
        if apiKey.isEmpty {
            SecItemDelete(baseQuery as CFDictionary)
            return
        }

        let data = Data(apiKey.utf8)
        let status = SecItemCopyMatching(baseQuery as CFDictionary, nil)

        if status == errSecSuccess {
            SecItemUpdate(
                baseQuery as CFDictionary,
                [kSecValueData as String: data] as CFDictionary
            )
        } else {
            var attributes = baseQuery
            attributes[kSecValueData as String] = data
            SecItemAdd(attributes as CFDictionary, nil)
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
