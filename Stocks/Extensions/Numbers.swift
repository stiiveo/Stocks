//
//  Numbers.swift
//  Stocks
//
//  Created by Jason Ou on 2021/8/22.
//

import Foundation

// MARK: - Number Formatter

extension NumberFormatter {
    /// Number formatter with percentage style and 2 decimal places.
    static let percentageFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    /// Number formatter with decimal style and 2 decimal places.
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
    
    func marketCapTextRepresentation() -> String {
        if Int(self / 1_000_000) > 0 {
            // Number is equal or bigger than one trillion.
            let formattedString = String(format: "%.3f", self / 1_000_000)
            return formattedString + "T"
        }
        else if Int(self / 1_000) > 0 {
            // Number is equal or bigger than one billion.
            let formattedString = String(format: "%.1f", self / 1_000)
            return formattedString + "B"
        }
        else {
            // Number is equal or bigger than one million.
            let formattedString = String(format: "%.0f", self / 1_000)
            return formattedString + "M"
        }
    }
    
}
