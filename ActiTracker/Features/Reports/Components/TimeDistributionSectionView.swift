//
//  TimeDistributionSectionView.swift
//  ActiTracker
//
//  Created by Julian David Rodriguez on 24/03/25.
//

import SwiftUI

struct TimeDistributionSectionView: View {
    let slices: [PieSliceData]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("report_time_distribution")
                .font(.title)
                .fontWeight(.bold)
            
            PieChartView(slices: slices)
                .frame(width: 200, height: 200)
        }
        .padding(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray, lineWidth: 1)
        )
        .padding(.horizontal)
    }
}
