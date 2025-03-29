//
//  ActivityBreakdownSectionView.swift
//  ActiTracker
//
//  Created by Julian David Rodriguez on 24/03/25.
//

import SwiftUI

struct ActivityBreakdownSectionView: View {
    let datosAgrupados: [(item: ActivityItem, totalTime: Int64)]
    let totalTracked: Double
    let formatTime: (Double) -> String
    let formatPercent: (Double) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("activity_breakdown")
                .font(.title)
                .fontWeight(.bold)
            
            ForEach(datosAgrupados, id: \.item.id) { entry in
                let percent = totalTracked > 0 ? Double(entry.totalTime) / totalTracked : 0
                let color = Color(hex: entry.item.wrappedColor)
                
                VStack {
                    HStack {
                        Circle()
                            .fill(color)
                            .frame(width: 15, height: 15)
                        Text(verbatim: "\(entry.item.name ?? "Actividad"): \(formatTime(Double(entry.totalTime)))")
                        Spacer()
                        Text(verbatim: "\(formatPercent(percent))%")
                            .fontWeight(.light)
                    }
                    ProgressView(value: percent)
                        .tint(color)
                }
            }
        }
        .padding(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray, lineWidth: 1)
        )
        .padding(.horizontal)
    }
}
