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
        XCTAssertFalse(CalendarDate.marketHolidays.contains(calendarDate), "Open date is a holiday.")
        
        // Test if the market open time is correct.
        XCTAssert(newYorkCalendar.component(.hour, from: openDate) == 9)
        XCTAssert(newYorkCalendar.component(.minute, from: openDate) == 30)
        
        // Test if the market closing time is correct.
        XCTAssert(newYorkCalendar.component(.minute, from: closeDate) == 0)
        
        if CalendarDate.marketEarlyCloseDates.contains(calendarDate) {
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
