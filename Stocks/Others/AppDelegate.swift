//
//  AppDelegate.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/9.
//

import UIKit
import Network

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    /// Get called when app launches.
    /// - Parameters:
    ///   - application: App instance
    ///   - launchOptions: Launch properties
    /// - Returns: Bool for success or failure.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Set up network monitor and update NetworkMonitor type property 'status'.
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            NetworkMonitor.updateStatus(path.status)
        }
        
        let networkMonitorQueue = DispatchQueue(label: "Monitor")
        monitor.start(queue: networkMonitorQueue)
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}

}

