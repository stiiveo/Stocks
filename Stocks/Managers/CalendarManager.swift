//
//  CalendarManager.swift
//  Stocks
//
//  Created by Jason Ou on 2021/8/20.
//

import Foundation

struct CalendarManager {
    
    // MARK: - Properties
    
    private var currentTime: Date { Date() }
    
    private let newYorkTimeZone = TimeZone(identifier: "America/New_York")
    
    var newYorkCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = newYorkTimeZone!
        return calendar
    }
    
    // MARK: - Private Methods
    
    private func isInHoliday(date: Date) -> Bool {
        let calendarDate = CalendarDate(year: newYorkCalendar.component(.year, from: date),
                                month: newYorkCalendar.component(.month, from: date),
                                day: newYorkCalendar.component(.day, from: date))
        return CalendarDate.marketHolidays.contains(calendarDate)
    }
    
    private func marketOpenTime(on date: Date) -> Date {
        let openTime = newYorkCalendar.date(bySettingHour: 9, minute: 30, second: 0, of: date)!
        let preciseOpenTime = newYorkCalendar.date(bySetting: .nanosecond, value: 0, of: openTime)!
        return preciseOpenTime
    }
    
    private func marketCloseTime(from date: Date) -> Date {
        let closeTime = newYorkCalendar.date(bySettingHour: 16, minute: 0, second: 0, of: date)!
        let preciseCloseTime = newYorkCalendar.date(bySetting: .nanosecond, value: 0, of: closeTime)!
        let earlyCloseDate = newYorkCalendar.date(bySetting: .hour, value: 13, of: preciseCloseTime)!
        let calendarDate = CalendarDate(year: newYorkCalendar.component(.year, from: date),
                                       month: newYorkCalendar.component(.month, from: date),
                                       day: newYorkCalendar.component(.day, from: date))
        
        // Change the market close hour to 13:00 if the provided calendar date is
        // the early close date.
        return CalendarDate.marketEarlyCloseDates.contains(calendarDate) ? earlyCloseDate : preciseCloseTime
    }
    
    /// Returns if the specified time is before the market is opened (i.e. Before 09:30 Eastern Time).
    /// - Parameter date: Point of time to be determined.
    /// - Returns: Boolean value on if the specified time is before the market is opened.
    private func isBeforeMarketOpenTime(at date: Date) -> Bool {
        return date < marketOpenTime(on: date)
    }
    
    /// A `Date` value which is within the previous trading day.
    /// - Note: If the current time is within a trading day but the market is not opened yet,
    ///         it returns a `Date` value within the previous trading day.
    private var latestTradingDate: Date {
        var date = isBeforeMarketOpenTime(at: currentTime) ? newYorkCalendar.date(byAdding: .day, value: -1, to: currentTime)! : currentTime
        while newYorkCalendar.isDateInWeekend(date) || isInHoliday(date: date) {
            // Reverse the current date for one day until it's not neither
            // in a weekend nor a holiday.
            date = newYorkCalendar.date(byAdding: .day, value: -1, to: date)!
        }
        return date
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss z"
        formatter.timeZone = newYorkTimeZone
        return formatter
    }
    
    /// The starting date in the given time span in which the latest trading day as the last day.
    /// - Parameter timeSpan: Duration of the time span.
    /// - Returns: Returns the starting date of the specified time span in which the latest trading day as the last day.
    private func unverifiedFirstMarketOpenDate(in timeSpan: TimeSpan) -> Date {
        let latestMarketOpenTime = latestTradingTime.open
        switch timeSpan {
        case .day:
            return latestTradingTime.open
        case .week:
            return newYorkCalendar.date(byAdding: .day, value: -7, to: latestMarketOpenTime)!
        case .month:
            return newYorkCalendar.date(byAdding: .month, value: -1, to: latestMarketOpenTime)!
        case .threeMonths:
            return newYorkCalendar.date(byAdding: .month, value: -3, to: latestMarketOpenTime)!
        case .sixMonths:
            return newYorkCalendar.date(byAdding: .month, value: -6, to: latestMarketOpenTime)!
        case .year:
            return newYorkCalendar.date(byAdding: .year, value: -1, to: latestMarketOpenTime)!
        case .twoYears:
            return newYorkCalendar.date(byAdding: .year, value: -2, to: latestMarketOpenTime)!
        case .fiveYears:
            return newYorkCalendar.date(byAdding: .year, value: -5, to: latestMarketOpenTime)!
        case .tenYears:
            return newYorkCalendar.date(byAdding: .year, value: -10, to: latestMarketOpenTime)!
        }
    }
    
    /// Returns a `Boolean` value indicating whether the current time is within the trading day.
    private var todayIsTradingDay: Bool {
        let todayIsInWeekend = newYorkCalendar.isDateInWeekend(currentTime)
        return !todayIsInWeekend && !isInHoliday(date: currentTime)
    }
    
    /// Returns a `Date` value which is within the trading day after today.
    private var dateInNextTradingDay: Date {
        var date = newYorkCalendar.date(byAdding: .day, value: 1, to: currentTime)!
        while newYorkCalendar.isDateInWeekend(date) || isInHoliday(date: date) {
            date = newYorkCalendar.date(byAdding: .day, value: 1, to: date)!
        }
        return date
    }
    
    /// Returns a `TradingTime` value of the next trading day.
    /// If today is trading day but the market is not opened yet, it returns today's `TradingTime`;
    /// If today is not a trading day or the market is opened already, it returns the next trading day's `TradingTime`.
    private var nextTradingTime: TradingTime {
        if todayIsTradingDay && currentTime < marketOpenTime(on: currentTime) {
            return TradingTime(open: marketOpenTime(on: currentTime),
                               close: marketCloseTime(from: currentTime))
        } else {
            return TradingTime(open: marketOpenTime(on: dateInNextTradingDay),
                               close: marketCloseTime(from: dateInNextTradingDay))
        }
    }
    
    // MARK: - Public
    
    /// The time span of the candle sticks data which starts from the specified time to the latest trading day.
    enum TimeSpan {
        case day
        case week
        case month
        case threeMonths
        case sixMonths
        case year
        case twoYears
        case fiveYears
        case tenYears
        
        var dataResolution: APICaller.DataResolution {
            switch self {
            case .day: return .minute
            case .week: return .fiveMinutes
            case .month: return .thirtyMinutes
            case .threeMonths: return .thirtyMinutes
            case .sixMonths: return .hour
            case .year: return .day
            case .twoYears: return .week
            case .fiveYears: return .week
            case .tenYears: return .week
            }
        }
    }
    
    struct TradingTime {
        let open: Date
        let close: Date
    }
    
    /// A `TradingTime` object indicating the latest trading day's trading time.
    ///
    /// If the current time is within a trading day and is after the market is opened,
    /// it returns today's `TradingTime`;
    /// If current time is in weekend or a holiday, it returns the previous trading day's `TradingTime`.
    var latestTradingTime: TradingTime {
        let openTime = marketOpenTime(on: latestTradingDate)
        let closeTime = marketCloseTime(from: latestTradingDate)
        
        return TradingTime(open: openTime, close: closeTime)
    }
    
    /// A `Boolean` value indicating whether the current time is within the trading time.
    var isMarketOpen: Bool {
        return currentTime >= latestTradingTime.open && currentTime < latestTradingTime.close
    }
    
    /// A `String` value of the current New York time formatted by preset date formatter.
    var currentNewYorkDate: String {
        return dateFormatter.string(from: currentTime)
    }
    
    /// Returns the first market open time on the specified days of time span, with the latest trading open time as the end of the time span.
    /// - Parameter days: The number of days of time span including the latest trading day.
    /// - Returns: Returns the first trading day's open time in the calculated time span or
    ///            the latest trading day's open time if everyday before the latest trading day is in weekend or is a holiday.
    public func firstMarketOpenTime(timeSpan: TimeSpan) -> Date {
        let unverifiedOpenDate = unverifiedFirstMarketOpenDate(in: timeSpan)

        // If the start day is in weekend or is a holiday, find the first trading day after it.
        var time = unverifiedOpenDate
        while (newYorkCalendar.isDateInWeekend(time) || isInHoliday(date: time)) && !newYorkCalendar.isDateInToday(time) {
            if let theDayAfter = newYorkCalendar.date(byAdding: .day, value: 1, to: time) {
                time = theDayAfter
            }
        }
        return time
    }
    
    /// Time (seconds) until the next trading session started.
    /// If the market is opened when this property is requested, this property will be 0.
    var timeToOpen: TimeInterval {
        if isMarketOpen {
            return 0
        } else {
            return nextTradingTime.open.timeIntervalSince1970 - currentTime.timeIntervalSince1970
        }
    }
    
    /// Time (seconds) until the current trading session ends.
    /// If the market is closed when this property is requested, this property will be 0.
    var timeToClose: TimeInterval {
        if isMarketOpen {
            return latestTradingTime.close.timeIntervalSince1970 - currentTime.timeIntervalSince1970
        } else {
            return 0
        }
    }
    
}
