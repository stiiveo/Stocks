//
//  WatchlistFloatingPanelLayout.swift
//  Stocks
//
//  Created by Jason Ou on 2021/8/30.
//

import Foundation
import FloatingPanel

class WatchlistFloatingPanelLayout: FloatingPanelLayout {
    var position: FloatingPanelPosition {
        return .bottom
    }
    
    var initialState: FloatingPanelState {
        return .tip
    }
    
    var anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring] {
        return [
            .full: FloatingPanelLayoutAnchor(absoluteInset: 150.0, edge: .top, referenceGuide: .superview),
            .half: FloatingPanelLayoutAnchor(fractionalInset: 0.45, edge: .bottom, referenceGuide: .superview),
            .tip: FloatingPanelLayoutAnchor(absoluteInset: 175.0, edge: .bottom, referenceGuide: .superview),
        ]
        
    }
}
