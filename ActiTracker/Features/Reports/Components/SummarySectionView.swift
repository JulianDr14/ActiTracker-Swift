//
//  SummarySectionView.swift
//  ActiTracker
//
//  Created by Julian David Rodriguez on 24/03/25.
//

import SwiftUI

struct SummarySectionView: View {
    let totalTracked: Double
    let trackedPercent: Double
    let untracked: Double
    let untrackedPercent: Double
    let formatTime: (Double) -> String
    let formatPercent: (Double) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("report_summary_header")
                .font(.title)
                .fontWeight(.bold)
            
            VStack {
                HStack {
                    Text("report_summary_tracked \(formatTime(totalTracked))")
                    Spacer()
                    Text(verbatim: "\(formatPercent(trackedPercent))%")
                        .fontWeight(.light)
                }
                ProgressView(value: trackedPercent)
            }
            
            VStack {
                HStack {
                    Text("report_summary_unaccounted \(formatTime(untracked))")
                    Spacer()
                    Text(verbatim: "\(formatPercent(untrackedPercent))%")
                        .fontWeight(.light)
                }
                ProgressView(value: untrackedPercent)
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
