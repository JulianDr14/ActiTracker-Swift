//
//  HomeView.swift
//  ActiTracker
//
//  Created by Julian David Rodriguez on 24/03/25.
//

import SwiftUI

struct HomeView: View {
    @State private var selection: Int = 1

    var body: some View {
        TabView(selection: $selection) {
            ActivityTimerView()
                .tabItem {
                    Label("home_timer", systemImage: "timer")
                }
                .tag(1)
            
            AddActivity()
                .tabItem {
                    Label("home_activities", systemImage: "list.bullet")
                }
                .tag(2)
            
            ReportsView()
                .tabItem {
                    Label("home_report", systemImage: "chart.bar")
                }
                .tag(3)
            SettingsView()
                .tabItem {
                    Label("home_settings", systemImage: "gear")
                }
                .tag(4)
            
        }
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
