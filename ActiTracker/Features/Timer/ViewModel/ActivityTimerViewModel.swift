//
//  ActivityTimerViewModel.swift
//  ActiTracker
//
//  Created by Julian David Rodriguez on 24/03/25.
//

import SwiftUI
import CoreData
import UIKit

@MainActor
final class ActivityTimerViewModel: ObservableObject {
    enum TimerStatus {
        case idle
        case running
        case paused
    }
    
    @Published var selectedActivity: ActivityItem?
    @Published var timeElapsed: TimeInterval = 0
    @Published private(set) var status: TimerStatus = .idle
    
    private let viewContext: NSManagedObjectContext
    private var timer: Timer?
    private var feedbackGenerator = UINotificationFeedbackGenerator()
    private var persistedTotalsByActivity: [UUID: TimeInterval] = [:]
    
    var isTimerRunning: Bool {
        status == .running
    }
    
    var isTimerPaused: Bool {
        status == .paused
    }
    
    var hasActiveSession: Bool {
        status != .idle
    }
    
    var currentSession: TimerSession? {
        TimerSessionStore.currentSession()
    }
    
    var formattedTime: String {
        format(timeElapsed)
    }
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        feedbackGenerator.prepare()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionDidChange),
            name: .timerSessionDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        reloadPersistedTotals()
        syncWithSession()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        timer?.invalidate()
    }
    
    func formattedTotalTime(for activity: ActivityItem) -> String {
        guard let activityId = activity.id else { return format(0) }
        let persistedTotal = persistedTotalsByActivity[activityId, default: 0]
        let runningContribution = TimerSessionStore.runningContribution(
            for: activityId,
            session: currentSession
        )
        return format(persistedTotal + runningContribution)
    }
    
    func select(activity: ActivityItem) {
        guard !hasActiveSession else { return }
        selectedActivity = activity
    }
    
    func startTimer() {
        guard let activity = selectedActivity,
              let activityId = activity.id else { return }
        
        Task {
            do {
                _ = try await TimerSessionStore.start(
                    activityId: activityId,
                    activityName: activity.name ?? "Actividad",
                    colorHex: activity.wrappedColor
                )
                vibrate(type: .success)
                syncWithSession()
            } catch {
                print("Error al iniciar el timer: \(error)")
            }
        }
    }
    
    func pauseTimer() {
        Task {
            do {
                _ = try await TimerSessionStore.pause()
                vibrate(type: .warning)
                syncWithSession()
            } catch {
                print("Error al pausar el timer: \(error)")
            }
        }
    }
    
    func resumeTimer() {
        Task {
            do {
                _ = try await TimerSessionStore.resume()
                vibrate(type: .success)
                syncWithSession()
            } catch {
                print("Error al reanudar el timer: \(error)")
            }
        }
    }
    
    func stopTimer() {
        Task {
            do {
                try await TimerSessionStore.stop()
                vibrate(type: .success)
                syncWithSession()
            } catch {
                print("Error al detener el timer: \(error)")
            }
        }
    }
    
    private func syncWithSession() {
        let session = TimerSessionStore.currentSession()
        reloadPersistedTotals()
        
        if let session {
            status = session.isRunning ? .running : .paused
            timeElapsed = TimerSessionStore.displayedElapsed(for: session)
            selectedActivity = fetchActivity(with: session.activityId) ?? selectedActivity
            session.isRunning ? startUITimer() : stopUITimer()
        } else {
            status = .idle
            timeElapsed = 0
            stopUITimer()
        }
    }
    
    private func startUITimer() {
        guard timer == nil else { return }
        
        let newTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshElapsedTime()
            }
        }
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
        refreshElapsedTime()
    }
    
    private func stopUITimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func refreshElapsedTime() {
        guard let session = TimerSessionStore.currentSession() else { return }
        timeElapsed = TimerSessionStore.displayedElapsed(for: session)
    }
    
    private func reloadPersistedTotals() {
        let request: NSFetchRequest<ActivityLog> = ActivityLog.fetchRequest()
        request.predicate = NSPredicate(
            format: "date == %@",
            Calendar.current.startOfDay(for: Date()) as NSDate
        )
        
        do {
            let logs = try viewContext.fetch(request)
            persistedTotalsByActivity = logs.reduce(into: [:]) { partialResult, log in
                guard let activityId = log.idActivityItem else { return }
                partialResult[activityId, default: 0] += TimeInterval(log.timeSpent)
            }
        } catch {
            print("Error al recargar los tiempos del día: \(error)")
            persistedTotalsByActivity = [:]
        }
    }
    
    private func fetchActivity(with activityId: UUID) -> ActivityItem? {
        let request: NSFetchRequest<ActivityItem> = ActivityItem.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", activityId as CVarArg)
        return try? viewContext.fetch(request).first
    }
    
    private func format(_ time: TimeInterval) -> String {
        let totalSeconds = max(0, Int(time.rounded(.down)))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func vibrate(type: UINotificationFeedbackGenerator.FeedbackType) {
        feedbackGenerator.notificationOccurred(type)
    }
    
    @objc private func sessionDidChange() {
        syncWithSession()
    }
    
    @objc private func appWillEnterForeground() {
        syncWithSession()
    }
    
    @objc private func appDidEnterBackground() {
        stopUITimer()
    }
}
