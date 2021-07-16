//
//  Extensions.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/10.
//

import Foundation
import UIKit
import SafariServices

// MARK: - UIColor

extension UIColor {
    /// Color used to fill the stock chart when stock price goes up.
    static let stockPriceUp: UIColor = {
        .systemGreen
    }()
    
    /// Color used to fill the stock chart when stock price goes down.
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
}

// MARK: - Notification

extension Notification.Name {
    /// Notification for when a symbol is added to the watch list.
    static let didAddToWatchList = Notification.Name("didAddToWatchList")
}

// MARK: - Date Formatter

extension DateFormatter {
    /// Date formatter with date format "YYYY-MM-dd".
    static let newsDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd"
        return formatter
    }()
    
    /// Date formatter with medium date style.
    static let mediumDateStyleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

// MARK: - Number Formatter

extension NumberFormatter {
    /// Number formatter with percentage style with maximum of 2 digits.
    static let percentageFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    /// Number formatter with decimal style with maximum of 2 digits.
    static let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()
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

// MARK: - Double

// REQUIRED TESTING BEFORE ADOPTION
extension Double {
    /// String value formatted by specified number formatter.
    /// - Parameter formatter: Number formatter used to format the double value.
    /// - Returns: Formatted string value.
    /// A string value converted by using string interpolation method will be returned if the formatting process failed.
    func stringFormatted(by formatter: NumberFormatter) -> String {
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
    
    /// Format the value to string with percentage style with maximum 2 decimal places.
    /// A percentage sign will be added to the end of the string.
    /// A plus sign will be added to the front of the string if the value is bigger than 0.
    /// - Returns: Returns string value formatted with percentage style.
    func stringWithPercentageStyle() -> String {
        let percentage = String(format: "%.2f", self * 100).appending("%")
        let signedPercentage = self > 0 ? "+" + percentage : percentage
        return signedPercentage
    }
}

// MARK: - Time Interval

extension TimeInterval {
    /// Date string created by using the specified date formatter.
    func dateString(formattedBy formatter: DateFormatter) -> String {
        let date = Date(timeIntervalSince1970: self)
        return formatter.string(from: date)
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
