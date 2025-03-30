//
//  ListActivities.swift
//  ActiTracker
//
//  Created by Julian David Rodriguez on 24/03/25.
//

import SwiftUI
import CoreData

struct ListActivities: View {
    var activities: FetchedResults<ActivityItem>
    
    @StateObject private var viewModel: ActivitiesViewModel

    // Inyección del NSManagedObjectContext a través del inicializador
    init(activities: FetchedResults<ActivityItem>, context: NSManagedObjectContext) {
        self.activities = activities
        _viewModel = StateObject(wrappedValue: ActivitiesViewModel(context: context))
    }
    
    var body: some View {
        List {
            ForEach(activities) { activity in
                HStack {
                    ColorCircleView(hex: activity.wrappedColor)
                    Text(activity.name ?? "Sin nombre")
                    Spacer()
                }
                .listRowInsets(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                .transition(.move(edge: .leading))
            }
            .onDelete { offsets in
                viewModel.deleteActivities(offsets: offsets, activities: activities)
            }
        }
        .listStyle(PlainListStyle())
        .scrollContentBackground(.hidden)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 5)
    }
}
