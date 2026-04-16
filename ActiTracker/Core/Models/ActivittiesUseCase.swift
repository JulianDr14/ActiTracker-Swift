//
//  ActivittiesUseCase.swift
//  ActiTracker
//
//  Created by Julian David Rodriguez on 24/03/25.
//

import Foundation
import ActivityKit

final class ActivittiesUseCase {
    enum LiveActivityError: LocalizedError {
        case activitiesDisabled
        
        var errorDescription: String? {
            switch self {
            case .activitiesDisabled:
                return "Live Activities are disabled on this device."
            }
        }
    }
    
    /// Inicia una Live Activity con el nombre, color y tiempo base proporcionados.
    /// - Parameter state: Estado inicial de la Live Activity.
    /// - Returns: El identificador de la actividad iniciada.
    static func startActivity(state: ActivitiesAttributes.ContentState) throws -> String {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw LiveActivityError.activitiesDisabled
        }
        
        let activityContent = ActivityContent(state: state, staleDate: nil)
        let attributes = ActivitiesAttributes()
        
        let activity = try Activity.request(attributes: attributes, content: activityContent)
        return activity.id
    }
    
    /// Actualiza la Live Activity identificada con nuevos valores.
    /// - Parameters:
    ///   - activityIdentifier: Identificador de la actividad a actualizar.
    ///   - state: Nuevo estado que debe mostrarse.
    static func updateActivity(activityIdentifier: String, state: ActivitiesAttributes.ContentState) async {
        let activity = activity(activityIdentifier: activityIdentifier)
        let activityContent = ActivityContent(state: state, staleDate: nil)
        
        await activity?.update(activityContent)
    }
    
    static func activity(activityIdentifier: String) -> Activity<ActivitiesAttributes>? {
        Activity<ActivitiesAttributes>.activities.first(where: { $0.id == activityIdentifier })
    }
    
    static func endOtherActivities(excluding activityIdentifier: String?) async {
        for activity in Activity<ActivitiesAttributes>.activities where activity.id != activityIdentifier {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
    
    /// Finaliza la Live Activity identificada.
    /// - Parameter activityIdentifier: Identificador de la actividad a finalizar.
    static func deleteActivity(activityIdentifier: String) async {
        let activity = activity(activityIdentifier: activityIdentifier)
        await activity?.end(nil, dismissalPolicy: .immediate)
    }
}
