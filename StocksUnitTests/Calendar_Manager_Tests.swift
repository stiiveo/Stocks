//
//  Calendar_Manager_Tests.swift
//  StocksUnitTests
//
//  Created by Jason Ou on 2021/8/20.
//

@testable import U_S__Stocks
import XCTest
import Foundation

class Calendar_Manager_Tests: XCTestCase {
    
    private let manager = CalendarManager()
    
    private let newYorkTimeZone = TimeZone(identifier: "America/New_York")
    
    private var newYorkCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = newYorkTimeZone!
        return calendar
    }
    
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
    
    private let earlyCloseDates: [CalendarDate] = [
        .init(year: 2021, month: 11, day: 26),
        .init(year: 2022, month: 11, day: 25),
        .init(year: 2023, month: 7, day: 3),
        .init(year: 2023, month: 11, day: 24)
    ]
    
    func test_latest_trading_time_interval() {
        let providedTradingTime = manager.latestTradingTime
        let openDate = providedTradingTime.open
        let closeDate = providedTradingTime.close
        
        // Test if provided open and closing date are in the same day.
        XCTAssert(newYorkCalendar.isDate(openDate, inSameDayAs: closeDate))
        
        // Test if provided trading date is in weekend.
        XCTAssertFalse(newYorkCalendar.isDateInWeekend(openDate), "Provided date is in weekend.")
        
        // Test if provided trading date is a holiday.
        let calendarDate = CalendarDate(year: newYorkCalendar.component(.year, from: openDate),
                                        month: newYorkCalendar.component(.month, from: openDate),
                                        day: newYorkCalendar.component(.day, from: openDate))
        XCTAssertFalse(marketHolidays.contains(calendarDate), "Open date is a holiday.")
        
        // Test if the market open time is correct.
        XCTAssert(newYorkCalendar.component(.hour, from: openDate) == 9)
        XCTAssert(newYorkCalendar.component(.minute, from: openDate) == 30)
        
        // Test if the market closing time is correct.
        XCTAssert(newYorkCalendar.component(.minute, from: closeDate) == 0)
        
        if earlyCloseDates.contains(calendarDate) {
            XCTAssert(newYorkCalendar.component(.hour, from: closeDate) == 13)
        } else {
            XCTAssert(newYorkCalendar.component(.hour, from: closeDate) == 16)
        }
    }
    
    func test_first_market_open_date_in_given_time_span() {
        let latestMarketOpenDate = manager.latestTradingTime.open
        let firstOpenDateInAWeek = manager.firstMarketOpenTime(timeSpan: .week)
        
        let firstOpenHour = newYorkCalendar.component(.hour, from: firstOpenDateInAWeek)
        let firstOpenMinute = newYorkCalendar.component(.minute, from: firstOpenDateInAWeek)
        XCTAssert(firstOpenHour == 9 && firstOpenMinute == 30,
                  "Open time is not 9:30 New York time. Returned: \(firstOpenHour):\(firstOpenMinute)")
        
        let timeIntervalDiff = latestMarketOpenDate.timeIntervalSince1970 - firstOpenDateInAWeek.timeIntervalSince1970
        XCTAssert(timeIntervalDiff <= 3600 * 24 * 7)
    }

}
