//
//  ActiTrackerApp.swift
//  ActiTracker
//
//  Created by Julian David Rodriguez on 23/03/25.
//

import SwiftUI

@main
struct ActiTrackerApp: App {
    
    let persistenceController = PersistenceController.shared
    
    init() {
        UIView.appearance().overrideUserInterfaceStyle = .light
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
