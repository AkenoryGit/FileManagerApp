//
//  KeychainService.swift
//  FileManagerApp
//
//  Created by Дмитрий Дудник on 27.08.2025.
//

import Foundation
import Security

protocol KeychainServiceProtocol {
    func save(_ password: String)
    func load() -> String?
    func update(_ password: String)
}

final class KeychainService: KeychainServiceProtocol {

    private let service = "com.example.FileManagerApp"
    private let account = "userPassword"

    func save(_ password: String) {
        let data = Data(password.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]

        SecItemAdd(query as CFDictionary, nil)
    }

    func load() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        guard status == errSecSuccess, let data = dataTypeRef as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func update(_ password: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: Data(password.utf8)
        ]

        SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    }
}
