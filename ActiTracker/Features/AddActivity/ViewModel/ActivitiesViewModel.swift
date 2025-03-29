//
//  ActivitiesViewModel.swift
//  ActiTracker
//
//  Created by Julian David Rodriguez on 29/03/25.
//

import SwiftUI
import CoreData

final class ActivitiesViewModel: ObservableObject {
    private let viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
    // Función para eliminar una actividad y sus registros asociados
    func delete(activity: ActivityItem) {
        guard let activityID = activity.id else { return }
        
        // Buscar y eliminar logs relacionados con la actividad
        let fetchRequest: NSFetchRequest<ActivityLog> = ActivityLog.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "idActivityItem == %@", activityID as CVarArg)
        
        do {
            let logsToDelete = try viewContext.fetch(fetchRequest)
            logsToDelete.forEach { viewContext.delete($0) }
            
            // Luego, eliminar la actividad
            viewContext.delete(activity)
            
            // Guardar cambios en el contexto
            try viewContext.save()
        } catch {
            print("Error al eliminar actividad o sus registros: \(error.localizedDescription)")
        }
    }
    
    // Función para eliminar múltiples actividades usando un IndexSet
    func deleteActivities(offsets: IndexSet, activities: FetchedResults<ActivityItem>) {
        offsets.map { activities[$0] }.forEach { delete(activity: $0) }
    }
}
