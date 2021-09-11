//
//  UIKits.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/10.
//

import Foundation
import UIKit
import SafariServices

// MARK: - UIColor

extension UIColor {
    /// Color used to represent a gainer stock.
    static let stockPriceUp: UIColor = {
        .systemGreen
    }()
    
    /// Color used to represent a loser stock.
    static let stockPriceDown: UIColor = {
        .systemRed
    }()
}

// MARK: - UIViewController

extension UIViewController {
    /// Present simple alert to the user with provided title and message.
    /// Alert action is composed of only a button with no action taken after being pressed.
    /// - Parameters:
    ///   - title: Title displayed on the alert view controller.
    ///   - message: Message displayed on the alert view controller
    ///   - actionTitle: Title of the action button.
    func showAlert(withTitle title: String, message: String, actionTitle: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        let dismissAction = UIAlertAction(title: actionTitle, style: .default, handler: nil)
        alert.addAction(dismissAction)
        present(alert, animated: true, completion: nil)
    }
    
    /// Present the standard Safari view controller initialized with specified URL.
    /// - Parameter url: The URL to navigate to. The URL must use the http or https scheme.
    func open(url: URL, withPresentationStyle style: UIModalPresentationStyle) {
        let safariVC = SFSafariViewController(url: url)
        safariVC.modalPresentationStyle = style
        present(safariVC, animated: true, completion: nil)
    }
    
    /// Present error alert with web link to Finnhub's API limit page.
    func presentAPIErrorAlert() {
        let alert = UIAlertController(title: "Data Unavailable",
                                      message: """
                                               Data sources are inaccessible due to \
                                               API limits. Tap "API Limit" for more info.
                                               """,
                                      preferredStyle: .alert)
        
        let dismissAction = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
        
        let openLinkAction = UIAlertAction(title: "API Limit", style: .cancel) { _ in
            let safariVC = SFSafariViewController(url: URL(string: "https://finnhub.io/pricing")!)
            safariVC.dismissButtonStyle = .close
            safariVC.modalPresentationStyle = .overFullScreen
            self.present(safariVC, animated: true) {
                alert.dismiss(animated: true, completion: nil)
            }
        }
        
        alert.addAction(openLinkAction)
        alert.addAction(dismissAction)
        present(alert, animated: true)
    }
    
}

// MARK: - UIImageView

extension UIImageView {
    /// Set up the image property with the image data downloaded from the provided URL object.
    /// - Parameter url: URL object consisted with http address of the image source.
    func setImage(with url: URL?) {
        guard let url = url else {
            print("Failed to create url object.")
            return
        }
        
        DispatchQueue.global(qos: .userInteractive).async {
            let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
                guard let data = data, error == nil else {
                    if data == nil { print("Downloaded data is nil") }
                    if let error = error { print(error.localizedDescription) }
                    return
                }
                DispatchQueue.main.async {
                    self?.image = UIImage(data: data)
                }
            }
            task.resume()
        }
    }
}

// MARK: - UIView

extension UIView {
    /// Add subview(s) to the view.
    /// - Parameter views: View(s) to be added as the subview(s).
    func addSubviews(_ views: UIView...) {
        views.forEach {
            addSubview($0)
        }
    }
    
    /// Width of view.
    var width: CGFloat {
        frame.width
    }
    
    /// Height of view.
    var height: CGFloat {
        frame.height
    }
    
    /// Left edge of view.
    var left: CGFloat {
        frame.origin.x
    }
    
    /// Right edge of view.
    var right: CGFloat {
        left + width
    }
    
    /// Top edge of view.
    var top: CGFloat {
        frame.origin.y
    }
    
    /// Bottom edge of view.
    var bottom: CGFloat {
        top + height
    }
}

// MARK: - StackView

extension UIStackView {
    func addArrangedSubviews(_ subviews: UIView...) {
        subviews.forEach { addArrangedSubview($0) }
    }
}
