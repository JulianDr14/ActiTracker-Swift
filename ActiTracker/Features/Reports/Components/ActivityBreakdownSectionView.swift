//
//  ActivityBreakdownSectionView.swift
//  ActiTracker
//
//  Created by Julian David Rodriguez on 24/03/25.
//

import SwiftUI

struct ActivityBreakdownSectionView: View {
    // MARK: - Propiedades
    let datosAgrupados: [(item: ActivityItem, totalTime: Int64)]
    let totalTracked: Double
    let formatTime: (Double) -> String
    let formatPercent: (Double) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("activity_breakdown")
                .font(.title)
                .fontWeight(.bold)
            
            if datosAgrupados.isEmpty {
                Text("No hay datos")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ForEach(datosAgrupados, id: \.item.id) { entry in
                    ActivityBreakdownRowView(
                        entry: entry,
                        totalTracked: totalTracked,
                        formatTime: formatTime,
                        formatPercent: formatPercent
                    )
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray, lineWidth: 1)
        )
    }
}


struct ActivityBreakdownSectionView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityBreakdownSectionView(
            datosAgrupados: [],
            totalTracked: 0,
            formatTime: { time in "\(Int(time)) seg" },
            formatPercent: { percent in String(format: "%.1f", percent * 100) }
        )
    }
}
