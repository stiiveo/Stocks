//
//  CalendarManager.swift
//  Stocks
//
//  Created by Jason Ou on 2021/8/20.
//

import Foundation

class CalendarManager {
    
    /// Source: [NYSE](https://www.nyse.com/markets/hours-calendars)
    private let holidayDates: [(Int, Int, Int)] = [
        (2021, 1, 1), (2021, 1, 18), (2021, 2, 15),
        (2021, 4, 2), (2021, 5, 31), (2021, 7, 5),
        (2021, 9, 6), (2021, 11, 25), (2021, 12, 24)
    ]
    
    private let currentTime = Date()
    
    private let newYorkTimeZone = TimeZone(identifier: "America/New_York")
    
    private var newYorkCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = newYorkTimeZone!
        return calendar
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .long
        formatter.timeZone = newYorkTimeZone
        return formatter
    }
    
    private let dateComponentUnits: Set<Calendar.Component> =
        [.year, .month, .day, .hour, .minute, .second, .nanosecond]
    
    private func newYorkDateComponents(from date: Date) -> DateComponents {
        return newYorkCalendar.dateComponents(dateComponentUnits, from: date)
    }
    
    private func isInHoliday(date: Date) -> Bool {
        let dateComponents = newYorkDateComponents(from: date)
        let literalDate = (dateComponents.year!, dateComponents.month!, dateComponents.day!)
        return holidayDates.contains{ $0 == literalDate }
    }
    
    private func marketOpenTime(from date: Date) -> TimeInterval {
        var components = newYorkDateComponents(from: date)
        components.hour = 9
        components.minute = 30
        components.second = 0
        components.nanosecond = 0
        return newYorkCalendar.date(from: components)!.timeIntervalSince1970
    }
    
    private func marketCloseTime(from date: Date) -> TimeInterval {
        var components = newYorkDateComponents(from: date)
        components.hour = 16
        components.minute = 0
        components.second = 0
        components.nanosecond = 0
        return newYorkCalendar.date(from: components)!.timeIntervalSince1970
    }
    
    private var latestTradingDate: Date {
        var date = currentTime
        while newYorkCalendar.isDateInWeekend(date) || isInHoliday(date: date) {
            // Reverse the current date for one day until it's not neither in a weekend nor a holiday.
            date = newYorkCalendar.date(byAdding: .day, value: -1, to: date)!
        }
        return date
    }
    
    /// The start and end of the latest market trading time.
    /// - Note: If current time is in weekend or a holiday, the method returns the time at the last trading date.
    var latestTradingTimeInterval: (TimeInterval, TimeInterval) {
        let openTime = marketOpenTime(from: latestTradingDate)
        let closeTime = marketCloseTime(from: latestTradingDate)
        
        print("Open Date:", dateFormatter.string(from: Date(timeIntervalSince1970: openTime)))
        print("Close Date:", dateFormatter.string(from: Date(timeIntervalSince1970: closeTime)))
        
        return (openTime, closeTime)
    }
    
}
