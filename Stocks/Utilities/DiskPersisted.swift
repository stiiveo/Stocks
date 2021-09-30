//
//  DiskPersisted.swift
//  Stocks
//
//  Created by Jason Ou on 2021/9/30.
//

import Foundation

@propertyWrapper struct DiskPersisted<Value: Codable> {
    var wrappedValue: Value {
        get {
            /// Try to retrieve `Value` from the specified `destination`.
            /// If failed, return `defaultValue`.
            
            if !FileManager.default.fileExists(atPath: fileUrl.path) {
                print("Persisting data does not exist:", fileUrl.absoluteString)
                return defaultValue
            }
            
            guard let persistedData = try? Data(contentsOf: fileUrl) else {
                print("Failed to retrieve data from persisting location:", fileUrl.absoluteString)
                return defaultValue
            }
            
            guard let persistedData = try? JSONDecoder().decode(Value.self, from: persistedData) else {
                print("Unable to decode persisted JSON data:", persistedData)
                return defaultValue
            }
            
            return persistedData
        }
        set {
            // Encode `StockData` into JSON format.
            guard let encodedData = try? JSONEncoder().encode(newValue) else {
                print("Unable to encode value to JSON object.")
                return
            }
            
            // Write encoded data to fileDirectory.
            do {
                try encodedData.write(to: fileUrl, options: .atomic)
            } catch {
                print("Failed to write data \(newValue) to destination \(fileUrl).")
            }
        }
    }
    
    private let defaultValue: Value
    private let fileUrl: URL
    private let storage = FileManager.default
    
    init(
        wrappedValue defaultValue: Value,
        fileURL: URL
    ) {
        self.defaultValue = defaultValue
        self.fileUrl = fileURL
    }
    
}
