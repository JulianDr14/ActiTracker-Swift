//
//  Persistence.swift
//  ActiTracker
//
//  Created by Julian David Rodriguez on 24/03/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ActivityModel")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Error al cargar la tienda persistente: \(error), \(error.userInfo)")
            }
        }
    }

    // Para las vistas de previsualización
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext

        // Creamos actividades de ejemplo
        var activityItems: [ActivityItem] = []
        for i in 0..<3 {
            let activity = ActivityItem(context: viewContext)
            activity.id = UUID()
            activity.name = "Actividad \(i + 1)"
            activity.color = ["FF0000", "00FF00", "0000FF"][i] // Rojo, verde, azul
            activityItems.append(activity)
        }

        // Creamos logs asociados a esas actividades (para hoy)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for item in activityItems {
            let log = ActivityLog(context: viewContext)
            log.id = UUID()
            log.date = today
            log.idActivityItem = item.id
            log.timeSpent = Int64(Int.random(in: 1800...7200)) // Entre 30 min y 2 horas
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Error al guardar datos de preview: \(nsError), \(nsError.userInfo)")
        }

        return controller
    }()
}
