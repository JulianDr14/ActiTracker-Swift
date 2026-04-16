//
//  LiveActivityInteractions.swift
//  ActiTracker
//
//  Created by Julian David Rodriguez on 16/04/26.
//

import Foundation
import CoreData
import ActivityKit
import AppIntents

extension Notification.Name {
    static let timerSessionDidChange = Notification.Name("timerSessionDidChange")
}

struct TimerSession: Codable, Equatable {
    let activityId: UUID
    let activityName: String
    let colorHex: String
    var sessionStartDate: Date?
    var accumulatedTodayAtStart: TimeInterval
    var pausedElapsedTime: TimeInterval?
    var liveActivityId: String?
    
    var isRunning: Bool {
        sessionStartDate != nil
    }
}

enum TimerSessionStore {
    enum SessionError: LocalizedError {
        case liveActivitiesDisabled
        
        var errorDescription: String? {
            switch self {
            case .liveActivitiesDisabled:
                return "Live Activities are disabled on this device."
            }
        }
    }
    
    private enum Constants {
        static let sessionKey = "active_timer_session"
        static let modelName = "ActivityModel"
        static let logEntityName = "ActivityLog"
        static let activityIdKey = "idActivityItem"
        static let dateKey = "date"
        static let timeSpentKey = "timeSpent"
        static let logIdentifierKey = "id"
    }
    
    private static let calendar = Calendar.current
    private static let defaults = UserDefaults.standard
    
    private static let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: Constants.modelName)
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("No se pudo cargar Core Data para Live Activity: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    static func currentSession() -> TimerSession? {
        guard let data = defaults.data(forKey: Constants.sessionKey) else { return nil }
        return try? JSONDecoder().decode(TimerSession.self, from: data)
    }
    
    static func displayedElapsed(for session: TimerSession, now: Date = Date()) -> TimeInterval {
        if let pausedElapsedTime = session.pausedElapsedTime, !session.isRunning {
            return pausedElapsedTime
        }
        
        return liveActivityState(for: session, now: now).elapsedTime
    }
    
    static func totalTime(for activityId: UUID, activeSession: TimerSession?, now: Date = Date()) -> TimeInterval {
        let dayStart = startOfDay(for: now)
        let persisted = totalLoggedTime(for: activityId, on: dayStart)
        
        guard let activeSession,
              activeSession.activityId == activityId,
              activeSession.isRunning,
              now > (activeSession.sessionStartDate ?? now),
              let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart),
              let sessionStartDate = activeSession.sessionStartDate else {
            return persisted
        }
        
        let overlapStart = max(sessionStartDate, dayStart)
        let overlapEnd = min(now, nextDay)
        return persisted + max(0, overlapEnd.timeIntervalSince(overlapStart))
    }
    
    static func start(activityId: UUID, activityName: String, colorHex: String) async throws -> TimerSession {
        let now = Date()
        let today = startOfDay(for: now)
        let accumulatedToday = totalLoggedTime(for: activityId, on: today)
        
        var session = TimerSession(
            activityId: activityId,
            activityName: activityName,
            colorHex: colorHex,
            sessionStartDate: now,
            accumulatedTodayAtStart: accumulatedToday,
            pausedElapsedTime: nil,
            liveActivityId: currentSession()?.liveActivityId
        )
        
        persist(session)
        try await syncLiveActivity(for: &session, now: now)
        postDidChange()
        return session
    }
    
    static func pause() async throws -> TimerSession? {
        guard var session = currentSession(),
              let sessionStartDate = session.sessionStartDate else {
            return currentSession()
        }
        
        let now = Date()
        try appendTrackedInterval(from: sessionStartDate, to: now, activityId: session.activityId)
        session.pausedElapsedTime = displayedElapsed(for: session, now: now)
        session.sessionStartDate = nil
        session.accumulatedTodayAtStart = totalLoggedTime(for: session.activityId, on: startOfDay(for: now))
        persist(session)
        try await syncLiveActivity(for: &session, now: now)
        postDidChange()
        return session
    }
    
    static func resume() async throws -> TimerSession? {
        guard var session = currentSession(),
              !session.isRunning else {
            return currentSession()
        }
        
        let now = Date()
        session.sessionStartDate = now
        session.accumulatedTodayAtStart = totalLoggedTime(for: session.activityId, on: startOfDay(for: now))
        session.pausedElapsedTime = nil
        persist(session)
        try await syncLiveActivity(for: &session, now: now)
        postDidChange()
        return session
    }
    
    static func stop() async throws {
        guard let session = currentSession() else { return }
        
        if let sessionStartDate = session.sessionStartDate {
            try appendTrackedInterval(from: sessionStartDate, to: Date(), activityId: session.activityId)
        }
        
        clearSession()
        
        if let liveActivityId = session.liveActivityId {
            await endLiveActivity(activityIdentifier: liveActivityId)
        } else {
            await endOtherLiveActivities(excluding: nil as String?)
        }
        
        postDidChange()
    }
    
    static func liveActivityState(for session: TimerSession, now: Date = Date()) -> ActivitiesAttributes.ContentState {
        if !session.isRunning {
            return ActivitiesAttributes.ContentState(
                name: session.activityName,
                colorHex: session.colorHex,
                elapsedTime: session.pausedElapsedTime ?? session.accumulatedTodayAtStart,
                timerStartDate: nil,
                isRunning: false
            )
        }
        
        guard let sessionStartDate = session.sessionStartDate else {
            return ActivitiesAttributes.ContentState(
                name: session.activityName,
                colorHex: session.colorHex,
                elapsedTime: session.accumulatedTodayAtStart,
                timerStartDate: nil,
                isRunning: false
            )
        }
        
        let today = startOfDay(for: now)
        let sameDayAsStart = calendar.isDate(sessionStartDate, inSameDayAs: now)
        
        let elapsedTime: TimeInterval
        let timerStartDate: Date
        
        if sameDayAsStart {
            elapsedTime = session.accumulatedTodayAtStart + max(0, now.timeIntervalSince(sessionStartDate))
            timerStartDate = sessionStartDate.addingTimeInterval(-session.accumulatedTodayAtStart)
        } else {
            let loggedToday = totalLoggedTime(for: session.activityId, on: today)
            let overlapStart = max(sessionStartDate, today)
            elapsedTime = loggedToday + max(0, now.timeIntervalSince(overlapStart))
            timerStartDate = overlapStart.addingTimeInterval(-loggedToday)
        }
        
        return ActivitiesAttributes.ContentState(
            name: session.activityName,
            colorHex: session.colorHex,
            elapsedTime: elapsedTime,
            timerStartDate: timerStartDate,
            isRunning: true
        )
    }
    
    @discardableResult
    private static func syncLiveActivity(for session: inout TimerSession, now: Date) async throws -> String? {
        let state = liveActivityState(for: session, now: now)
        
        if let liveActivityId = session.liveActivityId,
           currentLiveActivity(activityIdentifier: liveActivityId) != nil {
            await updateLiveActivity(activityIdentifier: liveActivityId, state: state)
            await endOtherLiveActivities(excluding: liveActivityId)
            return liveActivityId
        }
        
        let liveActivityId = try startLiveActivity(state: state)
        session.liveActivityId = liveActivityId
        persist(session)
        await endOtherLiveActivities(excluding: liveActivityId)
        return liveActivityId
    }
    
    private static func currentLiveActivity(activityIdentifier: String) -> Activity<ActivitiesAttributes>? {
        Activity<ActivitiesAttributes>.activities.first(where: { $0.id == activityIdentifier })
    }
    
    private static func startLiveActivity(state: ActivitiesAttributes.ContentState) throws -> String {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw SessionError.liveActivitiesDisabled
        }
        
        let activity = try Activity.request(
            attributes: ActivitiesAttributes(),
            content: ActivityContent(state: state, staleDate: nil)
        )
        return activity.id
    }
    
    private static func updateLiveActivity(activityIdentifier: String, state: ActivitiesAttributes.ContentState) async {
        let activity = currentLiveActivity(activityIdentifier: activityIdentifier)
        await activity?.update(ActivityContent(state: state, staleDate: nil))
    }
    
    private static func endLiveActivity(activityIdentifier: String) async {
        let activity = currentLiveActivity(activityIdentifier: activityIdentifier)
        await activity?.end(nil, dismissalPolicy: .immediate)
    }
    
    private static func endOtherLiveActivities(excluding activityIdentifier: String?) async {
        for activity in Activity<ActivitiesAttributes>.activities where activity.id != activityIdentifier {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
    
    private static func appendTrackedInterval(from startDate: Date, to endDate: Date, activityId: UUID) throws {
        guard endDate > startDate else { return }
        
        let context = persistentContainer.newBackgroundContext()
        var caughtError: Error?
        
        context.performAndWait {
            do {
                var cursor = startDate
                
                while cursor < endDate {
                    let dayStart = startOfDay(for: cursor)
                    guard let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart) else { break }
                    
                    let segmentEnd = min(endDate, nextDay)
                    let seconds = Int64((segmentEnd.timeIntervalSince(cursor)).rounded(.down))
                    
                    if seconds > 0 {
                        let log = try fetchOrCreateLog(for: activityId, on: dayStart, context: context)
                        let previous = log.value(forKey: Constants.timeSpentKey) as? Int64 ?? 0
                        log.setValue(previous + seconds, forKey: Constants.timeSpentKey)
                    }
                    
                    cursor = segmentEnd
                }
                
                if context.hasChanges {
                    try context.save()
                }
            } catch {
                caughtError = error
            }
        }
        
        if let caughtError {
            throw caughtError
        }
    }
    
    private static func fetchOrCreateLog(
        for activityId: UUID,
        on dayStart: Date,
        context: NSManagedObjectContext
    ) throws -> NSManagedObject {
        let request = NSFetchRequest<NSManagedObject>(entityName: Constants.logEntityName)
        request.fetchLimit = 1
        request.predicate = NSPredicate(
            format: "%K == %@ AND %K == %@",
            Constants.activityIdKey,
            activityId as CVarArg,
            Constants.dateKey,
            dayStart as NSDate
        )
        
        if let existing = try context.fetch(request).first {
            return existing
        }
        
        let log = NSEntityDescription.insertNewObject(forEntityName: Constants.logEntityName, into: context)
        log.setValue(UUID(), forKey: Constants.logIdentifierKey)
        log.setValue(dayStart, forKey: Constants.dateKey)
        log.setValue(activityId, forKey: Constants.activityIdKey)
        log.setValue(Int64(0), forKey: Constants.timeSpentKey)
        return log
    }
    
    private static func totalLoggedTime(for activityId: UUID, on dayStart: Date) -> TimeInterval {
        let context = persistentContainer.viewContext
        let request = NSFetchRequest<NSDictionary>(entityName: Constants.logEntityName)
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = [Constants.timeSpentKey]
        request.fetchLimit = 1
        request.predicate = NSPredicate(
            format: "%K == %@ AND %K == %@",
            Constants.activityIdKey,
            activityId as CVarArg,
            Constants.dateKey,
            dayStart as NSDate
        )
        
        do {
            return TimeInterval((try context.fetch(request).first?[Constants.timeSpentKey] as? Int64) ?? 0)
        } catch {
            print("Error al obtener el tiempo acumulado: \(error)")
            return 0
        }
    }
    
    private static func persist(_ session: TimerSession) {
        do {
            let data = try JSONEncoder().encode(session)
            defaults.set(data, forKey: Constants.sessionKey)
        } catch {
            print("Error al persistir la sesión: \(error)")
        }
    }
    
    private static func clearSession() {
        defaults.removeObject(forKey: Constants.sessionKey)
    }
    
    private static func postDidChange() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .timerSessionDidChange, object: nil)
        }
    }
    
    private static func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
}

struct PauseActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause Activity"
    
    func perform() async throws -> some IntentResult {
        _ = try? await TimerSessionStore.pause()
        return .result()
    }
}

struct ResumeActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Resume Activity"
    
    func perform() async throws -> some IntentResult {
        _ = try? await TimerSessionStore.resume()
        return .result()
    }
}

struct StopActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop Activity"
    
    func perform() async throws -> some IntentResult {
        try? await TimerSessionStore.stop()
        return .result()
    }
}
