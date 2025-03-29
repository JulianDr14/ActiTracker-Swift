//
//  ListActivitiesTimer.swift
//  ActiTracker
//
//  Created by Julian David Rodriguez on 29/03/25.
//

import SwiftUI

struct ListActivitiesTimer: View {
    var activities: FetchedResults<ActivityItem>
    @ObservedObject var viewModel: ActivityTimerViewModel
    
    var body: some View {
        List {
            ForEach(activities, id: \.id) { (activity: ActivityItem) in
                HStack {
                    ColorCircleView(hex: activity.wrappedColor)
                    Text(activity.name ?? "Sin nombre")
                    Spacer()
                    Text(viewModel.formattedTotalTime(for: activity))
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .listRowInsets(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            }
        }
        .listStyle(PlainListStyle())
        .scrollContentBackground(.hidden)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 5)
    }
}
