//
//  SceneDelegate.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/9.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    /// Main application window.
    var window: UIWindow?
    private let watchlistVC = WatchListViewController.sharedInstance

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        let vc = watchlistVC
        let navVC = UINavigationController(rootViewController: vc)
        window.rootViewController = navVC
        window.makeKeyAndVisible()
        
        self.window = window
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Initiate watchlist VC's data fetching timer.
        watchlistVC.initiateDataFetchingTimer()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Invalidate watchlist VC's data fetching timer.
        watchlistVC.invalidateDataFetchingTimer()
    }


}

