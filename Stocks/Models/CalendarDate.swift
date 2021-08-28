//
//  CalendarDate.swift
//  Stocks
//
//  Created by Jason Ou on 2021/8/27.
//

import Foundation

/// Calendar date structure consisting of 3 constant integer: `year`, `month`, `day`.
struct CalendarDate: Equatable {
    let year: Int
    let month: Int
    let day: Int
}

extension CalendarDate {
    
    /// Array of `CalendarDate` containing holidays of New York Stock Exchange from *2021* to *2023*.
    /// Source: [NYSE](https://www.nyse.com/markets/hours-calendars)
    static let marketHolidays: [CalendarDate] = [
        CalendarDate(year: 2021, month: 1, day: 1),
        CalendarDate(year: 2021, month: 1, day: 18),
        CalendarDate(year: 2021, month: 2, day: 15),
        CalendarDate(year: 2021, month: 4, day: 2),
        CalendarDate(year: 2021, month: 5, day: 31),
        CalendarDate(year: 2021, month: 7, day: 5),
        CalendarDate(year: 2021, month: 9, day: 6),
        CalendarDate(year: 2021, month: 11, day: 25),
        CalendarDate(year: 2021, month: 12, day: 24),
        CalendarDate(year: 2022, month: 1, day: 17),
        CalendarDate(year: 2022, month: 2, day: 21),
        CalendarDate(year: 2022, month: 4, day: 15),
        CalendarDate(year: 2022, month: 5, day: 30),
        CalendarDate(year: 2022, month: 7, day: 4),
        CalendarDate(year: 2022, month: 9, day: 5),
        CalendarDate(year: 2022, month: 11, day: 24),
        CalendarDate(year: 2022, month: 12, day: 26),
        CalendarDate(year: 2023, month: 1, day: 2),
        CalendarDate(year: 2023, month: 1, day: 16),
        CalendarDate(year: 2023, month: 2, day: 20),
        CalendarDate(year: 2023, month: 4, day: 7),
        CalendarDate(year: 2023, month: 5, day: 29),
        CalendarDate(year: 2023, month: 7, day: 4),
        CalendarDate(year: 2023, month: 9, day: 4),
        CalendarDate(year: 2023, month: 11, day: 23),
        CalendarDate(year: 2023, month: 12, day: 25)
    ]
    
    
    /// Array of `CalendarDate` containing early market close dates of New York Stock Exchange from *2021* to *2023*.
    /// Source: [NYSE](https://www.nyse.com/markets/hours-calendars)
    /// - Note: The market closes at *13:00 ET* on these dates.
    static let marketEarlyCloseDates: [CalendarDate] = [
        .init(year: 2021, month: 11, day: 26),
        .init(year: 2022, month: 11, day: 25),
        .init(year: 2023, month: 7, day: 3),
        .init(year: 2023, month: 11, day: 24)
    ]

}
