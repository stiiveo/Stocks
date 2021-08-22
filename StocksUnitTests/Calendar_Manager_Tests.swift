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
    
    private let holidayDates: [(Int, Int, Int)] = [
        (2021, 1, 1), (2021, 1, 18), (2021, 2, 15),
        (2021, 4, 2), (2021, 5, 31), (2021, 7, 5),
        (2021, 9, 6), (2021, 11, 25), (2021, 12, 24)
    ]
    
    private let earlyCloseDates: [(Int, Int, Int)] = [
        (2021, 11, 26), (2022, 11, 25), (2023, 7, 3), (2023, 11, 24)
    ]
    
    func test_latest_trading_time_interval() {
        let providedTimeInterval = manager.latestTradingTimeInterval
        let startDate = Date(timeIntervalSince1970: providedTimeInterval.0)
        let endDate = Date(timeIntervalSince1970: providedTimeInterval.1)
        
        let startDateComponents = newYorkCalendar.dateComponents(.normal, from: startDate)
        let endDateComponents = newYorkCalendar.dateComponents(.normal, from: endDate)
        
        // Test if the start time is precisely at 09:30 New York Time.
        XCTAssert(startDateComponents.hour == 9)
        XCTAssert(startDateComponents.minute == 30)
        
        // Test if the end time is precisely at 16:00 New York Time.
        XCTAssert(endDateComponents.hour == 16)
        XCTAssert(endDateComponents.minute == 0)
        
        // Test if provided start and end time are in the same day in New York.
        XCTAssert(startDateComponents.year == endDateComponents.year)
        XCTAssert(startDateComponents.month == endDateComponents.month)
        XCTAssert(startDateComponents.day == endDateComponents.day)
        
        // Test if provided trading day is in weekend.
        XCTAssertFalse(newYorkCalendar.isDateInWeekend(startDate),
                       "Start date is in weekend.")
        
        // Test if provided trading day is a holiday.
        let literalStartDate = (startDateComponents.year, startDateComponents.month, startDateComponents.day)
        XCTAssertFalse(holidayDates.contains{ $0 == literalStartDate },
                       "Start date is a holiday.")
    }
    
    func test_early_close_trading_time_interval() {
        let currentTime = Date()
        let currentDateComponents = newYorkCalendar.dateComponents(.normal, from: currentTime)
        let literalDate = (currentDateComponents.year!,
                           currentDateComponents.month!,
                           currentDateComponents.day!)
        
        // If the current date is one of the early close dates, test if the returned close hour is at 13:00.
        if earlyCloseDates.contains(where: { $0 == literalDate }) {
            let tradingTimeInterval = manager.latestTradingTimeInterval
            let closeDate = Date(timeIntervalSince1970: tradingTimeInterval.1)
            let closeDateComponents = newYorkCalendar.dateComponents(.normal, from: closeDate)
            XCTAssert(closeDateComponents.hour! == 13)
        }
    }

}
