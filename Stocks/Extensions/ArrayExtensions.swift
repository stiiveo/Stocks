//
//  ArrayExtensions.swift
//  Stocks
//
//  Created by Jason Ou on 2021/9/15.
//

import Foundation

extension Array {
    /// Move the element from the specified index to the new one.
    /// - Parameters:
    ///   - oldIndex: The index at which the element is.
    ///   - newIndex: The index to which the element is to be moved.
    mutating func move(from oldIndex: Int, to newIndex: Int) {
        if oldIndex == newIndex { return }
        if abs(oldIndex - newIndex) == 1 { return self.swapAt(oldIndex, newIndex) }
        self.insert(self.remove(at: oldIndex), at: newIndex)
    }
}

extension Array where Element: Hashable {
    func difference(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(other)
        return Array(thisSet.symmetricDifference(otherSet))
    }
}
