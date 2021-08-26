//
//  CalendarManager.swift
//  Stocks
//
//  Created by Jason Ou on 2021/8/20.
//

import Foundation

struct CalendarDate: Equatable {
    let year: Int
    let month: Int
    let day: Int
}

final class CalendarManager {
    
    // MARK: - Properties
    
    static let shared = CalendarManager()
    private init() {}
    
    private var currentTime: Date { Date() }
    
    private let newYorkTimeZone = TimeZone(identifier: "America/New_York")
    
    var newYorkCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = newYorkTimeZone!
        return calendar
    }
    
    /// Holidays of New York Stock Exchange.
    /// Source: [NYSE](https://www.nyse.com/markets/hours-calendars)
    /// - Description: The market is closed on these dates.
    /// - Note: Provides calendar date info in unit of year, month and day only.
    private let marketHolidays: [CalendarDate] = [
        .init(year: 2021, month: 1, day: 1),
        .init(year: 2021, month: 1, day: 18),
        .init(year: 2021, month: 2, day: 15),
        .init(year: 2021, month: 4, day: 2),
        .init(year: 2021, month: 5, day: 31),
        .init(year: 2021, month: 7, day: 5),
        .init(year: 2021, month: 9, day: 6),
        .init(year: 2021, month: 11, day: 25),
        .init(year: 2021, month: 12, day: 24),
        .init(year: 2022, month: 1, day: 17),
        .init(year: 2022, month: 2, day: 21),
        .init(year: 2022, month: 4, day: 15),
        .init(year: 2022, month: 5, day: 30),
        .init(year: 2022, month: 7, day: 4),
        .init(year: 2022, month: 9, day: 5),
        .init(year: 2022, month: 11, day: 24),
        .init(year: 2022, month: 12, day: 26),
        .init(year: 2023, month: 1, day: 2),
        .init(year: 2023, month: 1, day: 16),
        .init(year: 2023, month: 2, day: 20),
        .init(year: 2023, month: 4, day: 7),
        .init(year: 2023, month: 5, day: 29),
        .init(year: 2023, month: 7, day: 4),
        .init(year: 2023, month: 9, day: 4),
        .init(year: 2023, month: 11, day: 23),
        .init(year: 2023, month: 12, day: 25),
    ]
    
    /// Early market close dates of New York Stock Exchange.
    /// - Source: [NYSE](https://www.nyse.com/markets/hours-calendars)
    /// - Description: The market close early at 13:00 on these dates.
    /// - Note: Provides calendar date info in unit of year, month and day only.
    private let earlyCloseDates: [CalendarDate] = [
        .init(year: 2021, month: 11, day: 26),
        .init(year: 2022, month: 11, day: 25),
        .init(year: 2023, month: 7, day: 3),
        .init(year: 2023, month: 11, day: 24)
    ]
    
    // MARK: - Private Methods
    
    private func isInHoliday(date: Date) -> Bool {
        let calendarDate = CalendarDate(year: newYorkCalendar.component(.year, from: date),
                                month: newYorkCalendar.component(.month, from: date),
                                day: newYorkCalendar.component(.day, from: date))
        return marketHolidays.contains(calendarDate)
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
        return earlyCloseDates.contains(calendarDate) ? earlyCloseDate : preciseCloseTime
    }
    
    /// Returns if the specified time is before the market is opened (i.e. Before 09:30 Eastern Time).
    /// - Parameter date: Point of time to be determined.
    /// - Returns: Boolean value on if the specified time is before the market is opened.
    private func isBeforeMarketOpenTime(at date: Date) -> Bool {
        return date < marketOpenTime(on: date)
    }
    
    /// The last date on which the trading takes place.
    /// - Note: If the date on which this method is called is a valid trading day but the market is not opened yet,
    /// this method will return the previous trading date.
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
    
    /// The start and end of the latest market trading time.
    /// - Note: If current time is in weekend or a holiday, the method returns the time at the last trading date.
    var latestTradingTime: TradingTime {
        let openTime = marketOpenTime(on: latestTradingDate)
        let closeTime = marketCloseTime(from: latestTradingDate)
        
        return TradingTime(open: openTime, close: closeTime)
    }
    
    var isMarketOpen: Bool {
        return currentTime >= latestTradingTime.open && currentTime < latestTradingTime.close
    }
    
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
    
}
