//
//  ActivityBreakdownRowView.swift
//  ActiTracker
//
//  Created by Julian David Rodriguez on 30/03/25.
//

import SwiftUI

struct ActivityBreakdownRowView: View {
    let entry: (item: ActivityItem, totalTime: Int64)
    let totalTracked: Double
    let formatTime: (Double) -> String
    let formatPercent: (Double) -> String

    var body: some View {
        let percent = totalTracked > 0 ? Double(entry.totalTime) / totalTracked : 0
        let color = Color(hex: entry.item.wrappedColor)
        
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ColorCircleView(hex: entry.item.wrappedColor, width: 15, height: 15)
                Text("\(entry.item.name ?? "Actividad"): \(formatTime(Double(entry.totalTime)))")
                Spacer()
                Text("\(formatPercent(percent))%")
                    .fontWeight(.light)
            }
            
            AnimatedProgressBar(
                targetProgress: percent,
                color: color
            )
        }
    }
}
