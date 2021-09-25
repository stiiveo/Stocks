//
//  NotificationExtensions.swift
//  Stocks
//
//  Created by Jason Ou on 2021/9/15.
//

import Foundation

extension Notification.Name {
    static let didChangeEditingMode = Notification.Name("didChangeEditingMode")
    static let didTapAddToWatchlist = Notification.Name("didTapAddToWatchlist")
    static let apiLimitReached = Notification.Name("didReachApiLimit")
    static let dataAccessDenied = Notification.Name("dataAccessDenied")
}
