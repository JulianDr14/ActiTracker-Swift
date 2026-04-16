//
//  ActivitiesAttibutes.swift
//  ActiTracker
//
//  Created by Julian David Rodriguez on 24/03/25.
//

import Foundation
import ActivityKit

struct ActivitiesAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var name: String
        var colorHex: String
        var elapsedTime: TimeInterval
        var timerStartDate: Date?
        var isRunning: Bool
    }
}
