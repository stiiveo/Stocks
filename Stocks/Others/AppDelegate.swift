//
//  AppDelegate.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/9.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    /// Get called when app launches.
    /// - Parameters:
    ///   - application: App instance
    ///   - launchOptions: Launch properties
    /// - Returns: Bool for success or failure.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}

}

