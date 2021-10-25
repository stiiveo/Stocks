//
//  DateTime+Extension.swift
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
    
    /// A `String` value created by formatting the value to conventional time units: days, hours, minutes and seconds.
    /// If the value is not large enough to be carried to days unit, the unit is omitted.
    /// - Note: The value is rounded using the schoolbook rounding before the formatting operation.
    var formattedString: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .default
        return formatter.string(from: self) ?? ""
    }
}
