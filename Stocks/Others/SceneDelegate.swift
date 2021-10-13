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
    private let watchlistVC = WatchListViewController.shared

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        let navVC = UINavigationController(rootViewController: watchlistVC)
        window.rootViewController = navVC
        window.makeKeyAndVisible()
        
        self.window = window
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        WatchlistViewControllerViewModel.shared.initiateDataUpdater()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        WatchlistViewControllerViewModel.shared.invalidateDataUpdater()
    }

}

