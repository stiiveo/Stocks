//
//  AppDelegate.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/9.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        debug()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}

    private func debug() {
        APICaller.shared.news(for: .company(symbol: "MSFT")) { result in
            switch result {
            case .success(let news):
                print("news count:", news.count)
                for peace in news {
                    let date = Date(timeIntervalSince1970: peace.datetime)
                    print("Date:", date, "\n-")
                }
            case .failure(let error):
                print(error)
            }
        }
    }

}

