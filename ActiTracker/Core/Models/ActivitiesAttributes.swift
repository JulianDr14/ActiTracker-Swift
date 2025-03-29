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
        var baseTime: TimeInterval
        var name: String
        var colorHex: String
    }
}
