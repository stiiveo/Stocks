//
//  Numbers.swift
//  Stocks
//
//  Created by Jason Ou on 2021/8/22.
//

import Foundation

// MARK: - Number Formatter

extension NumberFormatter {
    /// Number formatter with percentage style with maximum of 2 digits.
    static let percentageFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    /// Number formatter with decimal style with maximum of 2 digits.
    static let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()
}

// MARK: - Double

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
    func signedPercentageString() -> String {
        let percentage = self.stringFormatted(by: .percentageFormatter)
        let signedPercentage = self > 0 ? "+" + percentage : percentage
        return signedPercentage
    }
}
