//
//  DiskPersisted.swift
//  Stocks
//
//  Created by Jason Ou on 2021/9/30.
//

import Foundation

/// New assigned value is encoded to JSON before being written to specified `URL`.
/// If the persisting process failed for any reason, the operation will be terminated.
/// - Note: The initially assigned value is returned if any error occurs during the retrieving of the persisted data.
@propertyWrapper struct DiskPersisted<T: Codable> {
    var wrappedValue: T {
        get {
            /// Return `defaultValue` if the specified `fileUrl` does not exist.
            if !FileManager.default.fileExists(atPath: fileUrl.path) {
                print("Persisting data does not exist:", fileUrl.absoluteString)
                return defaultValue
            }
            
            /// Return `defaultValue` if data cannot be retrieved from specified `fileUrl`.
            guard let persistedData = try? Data(contentsOf: fileUrl) else {
                print("Failed to retrieve data from persisting location:", fileUrl.absoluteString)
                return defaultValue
            }
            
            /// Return `defaultValue` if the retrieved data cannot be decoded to `Value` type object.
            guard let persistedData = try? JSONDecoder().decode(T.self, from: persistedData) else {
                print("Unable to decode persisted JSON data:", persistedData)
                return defaultValue
            }
            
            return persistedData
        }
        set {
            /// Create intermediate directories if it does not exist.
            var parentUrl = fileUrl
            parentUrl.deleteLastPathComponent()
            if !storage.fileExists(atPath: parentUrl.path) {
                try! storage.createDirectory(at: parentUrl,
                                             withIntermediateDirectories: true)
            }
            
            /// Encode `newValue` into JSON format.
            guard let encodedData = try? JSONEncoder().encode(newValue) else {
                print("Unable to encode value to JSON object.")
                return
            }
            
            /// Write encoded data to `fileUrl`.
            do {
                try encodedData.write(to: fileUrl, options: .atomic)
            } catch {
                print(error)
            }
        }
    }
    
    private let defaultValue: T
    private let fileUrl: URL
    private let storage = FileManager.default
    
    init(
        wrappedValue defaultValue: T,
        fileURL: URL
    ) {
        self.defaultValue = defaultValue
        self.fileUrl = fileURL
    }
    
}
