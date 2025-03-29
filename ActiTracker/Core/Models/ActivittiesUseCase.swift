//
//  ActivittiesUseCase.swift
//  ActiTracker
//
//  Created by Julian David Rodriguez on 24/03/25.
//

import Foundation
import ActivityKit

final class ActivittiesUseCase {
    /// Inicia una Live Activity con el nombre, color y tiempo base proporcionados.
    /// - Parameters:
    ///   - name: Nombre de la actividad.
    ///   - colorHex: Color en formato hexadecimal.
    ///   - baseTime: Tiempo inicial en segundos.
    /// - Returns: El identificador de la actividad iniciada.
    static func startActivity(name: String, colorHex: String, baseTime: TimeInterval) throws -> String {
        // Verifica si las Live Activities están habilitadas
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return "No se puede realizar la actividad"
        }
        
        // Se crea el estado inicial con el tiempo base que se quiere mostrar
        let initialState = ActivitiesAttributes.ContentState(baseTime: baseTime, name: name, colorHex: colorHex)
        
        // Se define una fecha futura para indicar cuándo la actividad se vuelve "stale"
        let futureDate: Date = .now + 3600
        
        // Se crea el contenido de la actividad con el estado inicial y la fecha de caducidad
        let activityContent = ActivityContent(state: initialState, staleDate: futureDate)
        
        // Se crean los atributos de la actividad (aquí usamos siempre ActivitiesAttributes)
        let attributes = ActivitiesAttributes()
        
        do {
            // Se solicita la Live Activity
            let activity = try Activity.request(attributes: attributes, content: activityContent)
            return activity.id
        } catch {
            throw error
        }
    }
    
    /// Actualiza la Live Activity identificada con nuevos valores.
    /// - Parameters:
    ///   - activityIdentifier: Identificador de la actividad a actualizar.
    ///   - name: Nuevo nombre de la actividad.
    ///   - colorHex: Nuevo color en hexadecimal.
    ///   - baseTime: Nuevo tiempo base.
    static func updateActivity(activityIdentifier: String, name: String, colorHex: String, baseTime: TimeInterval) async {
        let upgradeContentState = ActivitiesAttributes.ContentState(baseTime: baseTime, name: name, colorHex: colorHex)
        // Buscamos la actividad Live Activity por su identificador
        let activity = Activity<ActivitiesAttributes>.activities.first(where: { $0.id == activityIdentifier })
        let activityContent = ActivityContent(state: upgradeContentState, staleDate: .now + 3600)
        
        await activity?.update(activityContent)
    }
    
    /// Finaliza la Live Activity identificada.
    /// - Parameter activityIdentifier: Identificador de la actividad a finalizar.
    static func deleteActivity(activityIdentifier: String) async {
        let activity = Activity<ActivitiesAttributes>.activities.first(where: { $0.id == activityIdentifier })
        await activity?.end(nil)
    }
}
