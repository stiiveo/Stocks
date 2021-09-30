//
//  UserDefaultsPersisted.swift
//  Stocks
//
//  Created by Jason Ou on 2021/9/29.
//

import Foundation

@propertyWrapper struct UserDefaultsPersisted<Value> {
    var wrappedValue: Value {
        get {
            let value = storage.value(forKey: key) as? Value
            return value ?? defaultValue
        }
        set {
            storage.setValue(newValue, forKey: key)
        }
    }
    
    private let key: String
    private let defaultValue: Value
    private let storage = UserDefaults.standard
    
    init(wrappedValue defaultValue: Value,
         key: String) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
}
