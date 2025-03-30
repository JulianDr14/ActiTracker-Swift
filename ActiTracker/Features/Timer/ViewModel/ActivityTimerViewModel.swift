//
//  ActivityTimerViewModel.swift
//  ActiTracker
//
//  Created by Julian David Rodriguez on 24/03/25.
//

import SwiftUI
import CoreData
import Combine
import ActivityKit
import UIKit

class ActivityTimerViewModel: ObservableObject {
    // MARK: - Propiedades
    @Published var selectedActivity: ActivityItem?
    @Published var isTimerRunning: Bool = false
    @Published var timeElapsed: TimeInterval = 0
    
    private var timer: Timer?  // Timer para actualizar la UI (en primer plano)
    private var backgroundTimer: DispatchSourceTimer?  // Timer para actualizar la Live Activity en background
    private var cancellables = Set<AnyCancellable>()
    private let viewContext: NSManagedObjectContext
    private let today: Date = Calendar.current.startOfDay(for: Date())
    
    private var feedbackGenerator = UINotificationFeedbackGenerator()
    
    // Identificador de la Live Activity
    private var liveActivityId: String?
    
    // Propiedad para almacenar la fecha de inicio
    private var startTime: Date?
    
    // Variable para controlar la actualización en el timer de UI
    private var lastLiveActivityUpdate: TimeInterval = 0
    
    // MARK: - Inicializador
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        
        // Preparar el feedback generator
        feedbackGenerator.prepare()
        
        // Observadores del ciclo de vida de la app
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Funciones de Actividad
    func totalTime(for activity: ActivityItem) -> TimeInterval {
        let fetchRequest: NSFetchRequest<ActivityLog> = ActivityLog.fetchRequest()
        let today = Calendar.current.startOfDay(for: Date())
        fetchRequest.predicate = NSPredicate(
            format: "idActivityItem == %@ AND date == %@",
            activity.id! as CVarArg,
            today as NSDate
        )
        do {
            let logs = try viewContext.fetch(fetchRequest)
            return logs.reduce(0) { $0 + TimeInterval($1.timeSpent) }
        } catch {
            print("Error al obtener logs para la actividad \(activity.name ?? ""): \(error)")
            return 0
        }
    }
    
    // Propiedad computada para el tiempo formateado
    var formattedTime: String {
        let hours = Int(timeElapsed) / 3600
        let minutes = (Int(timeElapsed) % 3600) / 60
        let seconds = Int(timeElapsed) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func formattedTotalTime(for activity: ActivityItem) -> String {
        let total = Int(totalTime(for: activity))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // MARK: - Funciones de Timer y Live Activity
    func toggleTimer() {
        isTimerRunning ? stopTimer() : startTimer()
        vibrate(type: .success)
    }
    
    func vibrate(type: UINotificationFeedbackGenerator.FeedbackType) {
        feedbackGenerator.notificationOccurred(type)
    }
    
    private func startTimer() {
        guard let activity = selectedActivity,
              let activityId = activity.id else {
            print("Error: activity.id es nil")
            return
        }
        
        // Verificar si ya existe un log para hoy y configurar el tiempo transcurrido y la fecha de inicio
        let fetchRequest: NSFetchRequest<ActivityLog> = ActivityLog.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "idActivityItem == %@ AND date == %@",
            activityId as CVarArg,
            today as NSDate
        )
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            if let existingLog = results.first {
                timeElapsed = TimeInterval(existingLog.timeSpent)
                // Se ajusta la fecha de inicio restando el tiempo acumulado previamente
                startTime = Date().addingTimeInterval(-timeElapsed)
            } else {
                timeElapsed = 0
                startTime = Date()
            }
        } catch {
            print("Error al buscar log de hoy: \(error)")
            timeElapsed = 0
            startTime = Date()
        }
        
        // Iniciar la Live Activity con el valor inicial
        do {
            let name = activity.name ?? "Actividad"
            let colorHex = activity.wrappedColor  // Asegúrate de que wrappedColor sea un String hexadecimal
            liveActivityId = try ActivittiesUseCase.startActivity(name: name,
                                                                  colorHex: colorHex,
                                                                  baseTime: timeElapsed)
        } catch {
            print("Error al iniciar Live Activity: \(error)")
        }
        
        isTimerRunning = true
        lastLiveActivityUpdate = timeElapsed
        
        // Iniciar el timer para la UI
        startUITimer()
    }
    
    private func startUITimer() {
        // Actualiza la UI cada segundo mientras la app está en primer plano
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }
            self.timeElapsed = Date().timeIntervalSince(startTime)
            
            // Actualiza la Live Activity cada 10 segundos desde la UI
            if self.timeElapsed - self.lastLiveActivityUpdate >= 10 {
                self.lastLiveActivityUpdate = self.timeElapsed
                if let liveActivityId = self.liveActivityId, let activity = self.selectedActivity {
                    let name = activity.name ?? "Actividad"
                    let colorHex = activity.wrappedColor
                    Task {
                        await ActivittiesUseCase.updateActivity(activityIdentifier: liveActivityId,
                                                                name: name,
                                                                colorHex: colorHex,
                                                                baseTime: self.timeElapsed)
                    }
                }
            }
        }
    }
    
    private func stopUITimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func startBackgroundTimer() {
        // Se usa un DispatchSourceTimer para actualizar la Live Activity cada 10 segundos en background
        backgroundTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .background))
        backgroundTimer?.schedule(deadline: .now(), repeating: 10)
        backgroundTimer?.setEventHandler { [weak self] in
            guard let self = self, let startTime = self.startTime else { return }
            let updatedTime = Date().timeIntervalSince(startTime)
            // Ejecutar la actualización en el hilo principal:
            DispatchQueue.main.async {
                self.timeElapsed = updatedTime
                if let liveActivityId = self.liveActivityId, let activity = self.selectedActivity {
                    let name = activity.name ?? "Actividad"
                    let colorHex = activity.wrappedColor
                    Task {
                        await ActivittiesUseCase.updateActivity(activityIdentifier: liveActivityId,
                                                                name: name,
                                                                colorHex: colorHex,
                                                                baseTime: self.timeElapsed)
                    }
                }
            }
        }
        backgroundTimer?.resume()
    }
    
    private func stopBackgroundTimer() {
        backgroundTimer?.cancel()
        backgroundTimer = nil
    }
    
    private func stopTimer() {
        guard let activity = selectedActivity,
              let activityId = activity.id else {
            print("Error: activity.id es nil")
            return
        }
        
        isTimerRunning = false
        stopUITimer()
        stopBackgroundTimer()
        
        // Guardar el tiempo final en Core Data
        let fetchRequest: NSFetchRequest<ActivityLog> = ActivityLog.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "idActivityItem == %@ AND date == %@",
            activityId as CVarArg,
            today as NSDate
        )
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            let log: ActivityLog
            
            if let existingLog = results.first {
                log = existingLog
            } else {
                log = ActivityLog(context: viewContext)
                log.id = UUID()
                log.date = today
                log.idActivityItem = activityId
                log.timeSpent = 0
            }
            
            log.timeSpent = Int64(timeElapsed)
            try viewContext.save()
        } catch {
            print("Error al guardar log: \(error)")
        }
        
        timeElapsed = 0
        startTime = nil
        
        // Finalizar la Live Activity
        if let liveActivityId = liveActivityId {
            Task {
                await ActivittiesUseCase.deleteActivity(activityIdentifier: liveActivityId)
                print("Actividad detenida")
            }
            self.liveActivityId = nil
        }
    }
    
    // MARK: - Manejo del ciclo de vida de la app
    @objc private func appDidEnterBackground() {
        // Al pasar a background se detiene el timer de UI y se inicia el de background
        stopUITimer()
        startBackgroundTimer()
    }
    
    @objc private func appWillEnterForeground() {
        // Al volver a primer plano se cancela el timer de background y se reanuda el timer de UI
        stopBackgroundTimer()
        startUITimer()
    }
}
