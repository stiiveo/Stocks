//
//  HapticsManager.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/9.
//

import Foundation
import UIKit

struct HapticsManager {
    
    // MARK: - Public
    
    /// Vibrate lightly for a selection tap interaction.
    public func vibrateForSelection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    // Vibrate for type
    /// Generate haptic feedback for given type of event.
    /// - Parameter type: Type of the feedback.
    public func vibrate(for type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
