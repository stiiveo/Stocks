//
//  Extensions.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/10.
//

import Foundation
import UIKit

// MARK: - Alert

extension UIViewController {
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
}

// MARK: - Notification

extension Notification.Name {
    static let didAddToWatchList = Notification.Name("didAddToWatchList")
}

// MARK: - Number Formatter

extension NumberFormatter {
    
    static let percentageFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
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

// MARK: - String

extension String {
    /// Create date string value by formatting provided time interval value with preset style.
    static func string(from timeInterval: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timeInterval)
        return DateFormatter.prettyDateFormatter.string(from: date)
    }
    
    static func percentage(from double: Double) -> String {
        let formatter = NumberFormatter.percentageFormatter
        return formatter.string(from: NSNumber(value: double)) ?? "\(double)"
    }
    
    static func decimalFormatted(from double: Double) -> String {
        let formatter = NumberFormatter.decimalFormatter
        return formatter.string(from: NSNumber(value: double)) ?? "\(double)"
    }
    
    static func stockPriceChangePercentage(from priceChange: Double) -> String {
        let percentage = String(format: "%.2f", priceChange * 100).appending("%")
        let signedPercentage = priceChange > 0 ? "+" + percentage : percentage
        return signedPercentage
    }
    
}

// MARK: - Date Formatter

extension DateFormatter {
    static let newsDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd"
        return formatter
    }()
    
    static let prettyDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

// MARK: - Add Subview

extension UIView {
    func addSubviews(_ views: UIView...) {
        views.forEach {
            addSubview($0)
        }
    }
}

// MARK: - Framing

extension UIView {
    var width: CGFloat {
        frame.size.width
    }
    
    var height: CGFloat {
        frame.size.height
    }
    
    var left: CGFloat {
        frame.origin.x
    }
    
    var right: CGFloat {
        left + width
    }
    
    var top: CGFloat {
        frame.origin.y
    }
    
    var bottom: CGFloat {
        top + height
    }
}
