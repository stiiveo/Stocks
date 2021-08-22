//
//  Date and Calendar.swift
//  Stocks
//
//  Created by Jason Ou on 2021/8/22.
//

import Foundation

// MARK: - Calendar

extension Set where Element == Calendar.Component {
    static var normal: Self {
        [.year, .month, .day, .hour, .minute, .second, .nanosecond]
    }
}

// MARK: - Date

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

// MARK: - Time Interval

extension TimeInterval {
    /// Date string created by using the specified date formatter.
    func dateString(formattedBy formatter: DateFormatter) -> String {
        let date = Date(timeIntervalSince1970: self)
        return formatter.string(from: date)
    }
}
