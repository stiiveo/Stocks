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
    
    static func maxFractionDigits(_ maxFractionDigits: Int) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = maxFractionDigits
        return formatter
    }
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
    
    /// Returns the closest number of powers of ten in *short scale* system of which the value is equal or less than the given value.
    /// - Reference: [Wikipedia: Long and Short Scale Comparison](https://en.wikipedia.org/wiki/Long_and_short_scale#Comparison)
    /// - Parameter value: The value used to determine the closest powers of ten in *short scale* system.
    /// - Returns: The number of powers of ten
    private func closestPowersOfTen(from value: Double) -> Int {
        switch value {
        case pow(10, 15)..<pow(10, 18):
            return 15
        case pow(10, 12)..<pow(10, 15):
            return 12
        case pow(10, 9)..<pow(10, 12):
            return 9
        case pow(10, 6)..<pow(10, 9):
            return 6
        case pow(10, 3)..<pow(10, 6):
            return 3
        default:
            return 0
        }
    }
    
    /// Short scale names for integer powers of ten. Each case's raw value represent the symbol of its metric prefix.
    /// - Reference: [Wikipedia: Long and Short Scale Comparison](https://en.wikipedia.org/wiki/Long_and_short_scale#Comparison)
    private func metricPrefix(inNumberOfPowersOfTen numberOfPowersOfTen: Int) -> String {
        switch numberOfPowersOfTen {
        case 15: return "P"
        case 12: return "T"
        case 9: return "B"
        case 6: return "M"
        case 3: return "k"
        default: return ""
        }
    }
    
    /// Convert the value to short scale text representation followed by the symbol of its metric prefix.
    /// - Note: If the value is between a trillion and a million, it returns a text representation in unit of billion.
    ///         Metric prefix examples: Million: *M*, Billion: *B*, Trillion: *T*, Quadrillion: *P*.
    /// - Reference: [Wikipedia: Long and Short Scale Comparison](https://en.wikipedia.org/wiki/Long_and_short_scale#Comparison)
    /// - Returns: Text representation of the value with 4 digits including the decimal number followed by an acronym of the unit.
    func shortScaleText() -> String {
        let numberOfDigits = Int(log10(self).rounded(.towardZero))
        let closestPowersOfTen = closestPowersOfTen(from: self)
        let maxIntegerDigits: Int = 4
        
        let valueInShortScaleUnit = self / pow(10, Double(closestPowersOfTen))
        let integerDigits = numberOfDigits - closestPowersOfTen + 1
        let maxFractionDigits = maxIntegerDigits - integerDigits
        let formatter = NumberFormatter.maxFractionDigits(maxFractionDigits)
        let formattedString = formatter.string(from: NSNumber(value: valueInShortScaleUnit))
        return formattedString! + metricPrefix(inNumberOfPowersOfTen: closestPowersOfTen)
    }
    
}
