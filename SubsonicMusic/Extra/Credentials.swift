//
//  Credentials.swift
//  SubsonicMusic
//
//  Created by Arna13 on 13/6/23.
//

import Foundation
import Security

struct Credentials {
    let baseURL: URL
    let username: String
    let password: String
}

func storeCredentials(_ credentials: Credentials) {
    let baseURLData = credentials.baseURL.absoluteString.data(using: .utf8)!
    
    var attributes: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: credentials.username,
        kSecAttrService as String: "SubsonicAPI",
        kSecValueData as String: baseURLData,
        kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
    ]
    
    var status = SecItemCopyMatching(attributes as CFDictionary, nil)
    
    if status == errSecSuccess {
        let updateAttributes: [String: Any] = [
            kSecValueData as String: baseURLData
        ]
        
        status = SecItemUpdate(attributes as CFDictionary, updateAttributes as CFDictionary)
        
        if status != errSecSuccess {
            print("Error updating keychain item: \(status)")
        }
    } else if status == errSecItemNotFound {
        status = SecItemAdd(attributes as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("Error adding keychain item: \(status)")
        }
    } else {
        print("Error accessing keychain: \(status)")
    }
    
    attributes[kSecAttrAccount as String] = credentials.username + "-password"
    attributes[kSecValueData as String] = credentials.password.data(using: .utf8)!
    
    status = SecItemCopyMatching(attributes as CFDictionary, nil)
    
    if status == errSecSuccess {
        let updateAttributes: [String: Any] = [
            kSecValueData as String: credentials.password.data(using: .utf8)!
        ]
        
        status = SecItemUpdate(attributes as CFDictionary, updateAttributes as CFDictionary)
        
        if status != errSecSuccess {
            print("Error updating keychain item: \(status)")
        }
    } else if status == errSecItemNotFound {
        status = SecItemAdd(attributes as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("Error adding keychain item: \(status)")
        }
    } else {
        print("Error accessing keychain: \(status)")
    }
}

func loadCredentials() -> Credentials? {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "SubsonicAPI",
        kSecMatchLimit as String: kSecMatchLimitOne,
        kSecReturnAttributes as String: true,
        kSecReturnData as String: true
    ]
    
    var itemRef: CFTypeRef?
    var status = SecItemCopyMatching(query as CFDictionary, &itemRef)
    
    guard status == errSecSuccess else {
        print("Error accessing keychain: \(status)")
        return nil
    }
    
    guard let item = itemRef as? [String : Any],
          let baseURLData = item[kSecValueData as String] as? Data,
          let baseURLString = String(data: baseURLData, encoding: .utf8),
          let baseURL = URL(string: baseURLString),
          let username = item[kSecAttrAccount as String] as? String else {
              return nil
          }
    
    var passwordQuery = query
    passwordQuery[kSecAttrAccount as String] = username + "-password"
    
    status = SecItemCopyMatching(passwordQuery as CFDictionary, &itemRef)
    
    guard status == errSecSuccess else {
        print("Error accessing keychain: \(status)")
        return nil
    }
    
    guard let passwordItem = itemRef as? [String : Any],
          let passwordData = passwordItem[kSecValueData as String] as? Data,
          let password = String(data: passwordData, encoding: .utf8) else {
              return nil
          }
    
    return Credentials(baseURL: baseURL, username: username, password: password)
}

func deleteCredentials() {
    var query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "SubsonicAPI"
    ]
    
    var status = SecItemDelete(query as CFDictionary)
    
    if status != errSecSuccess && status != errSecItemNotFound {
        print("Error deleting keychain item: \(status)")
    }
    
    query[kSecAttrAccount as String] = "-password"
    
    status = SecItemDelete(query as CFDictionary)
    
    if status != errSecSuccess && status != errSecItemNotFound {
        print("Error deleting keychain item: \(status)")
    }
}
