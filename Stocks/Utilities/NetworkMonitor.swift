//
//  NetworkMonitor.swift
//  Stocks
//
//  Created by Jason Ou on 2021/10/25.
//

import Foundation
import Network

class NetworkMonitor {
    
    enum Status {
        case available, notAvailable, unestablished
    }
    
    private(set) static var status: Status = .notAvailable {
        didSet {
            print("Network Status:", status)
            if status == .available {
                NotificationCenter.default.post(name: .networkIsAvailable, object: nil)
            }
            
            if status == .notAvailable {
                NotificationCenter.default.post(name: .networkIsUnavailable, object: nil)
            }
        }
    }
    
    static func updateStatus(_ status: NWPath.Status) {
        switch status {
        case .satisfied:
            NetworkMonitor.status = .available
        case .unsatisfied:
            NetworkMonitor.status = .notAvailable
        case .requiresConnection:
            NetworkMonitor.status = .unestablished
        @unknown default:
            print("New network status case is available but action to take is undetermined.")
            break
        }
    }

}
