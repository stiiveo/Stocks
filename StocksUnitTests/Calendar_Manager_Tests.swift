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
    
    private let dateComponentUnits: Set<Calendar.Component> =
        [.year, .month, .day, .hour, .minute, .second, .nanosecond]
    
    private let holidayDates: [(Int, Int, Int)] = [
        (2021, 1, 1), (2021, 1, 18), (2021, 2, 15),
        (2021, 4, 2), (2021, 5, 31), (2021, 7, 5),
        (2021, 9, 6), (2021, 11, 25), (2021, 12, 24)
    ]
    
    func test_latest_trading_time_interval() {
        let providedTimeInterval = manager.latestTradingTimeInterval
        let startDate = Date(timeIntervalSince1970: providedTimeInterval.0)
        let endDate = Date(timeIntervalSince1970: providedTimeInterval.1)
        
        let startDateComponents = newYorkCalendar.dateComponents(dateComponentUnits, from: startDate)
        let endDateComponents = newYorkCalendar.dateComponents(dateComponentUnits, from: endDate)
        
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

}
