//
//  ReportsViewModel.swift
//  ActiTracker
//
//  Created by Julian David Rodriguez on 24/03/25.
//

import SwiftUI
import CoreData

class ReportsViewModel: ObservableObject {
    // Propiedad que controla la fecha seleccionada
    @Published var selectedDate: Date = Date() {
        didSet {
            actualizarPredicado()
        }
    }
    
    // Predicado que se actualiza al cambiar la fecha
    @Published var logsPredicate: NSPredicate = {
        let calendar = Calendar.current
        let inicio = calendar.startOfDay(for: Date())
        let fin = calendar.date(byAdding: .day, value: 1, to: inicio)!
        return NSPredicate(format: "date >= %@ AND date < %@", inicio as NSDate, fin as NSDate)
    }()
    
    let secondsInDay: Double = 86400

    // Actualiza el predicado en función de la fecha seleccionada
    private func actualizarPredicado() {
        let calendar = Calendar.current
        let inicio = calendar.startOfDay(for: selectedDate)
        let fin = calendar.date(byAdding: .day, value: 1, to: inicio)!
        logsPredicate = NSPredicate(format: "date >= %@ AND date < %@", inicio as NSDate, fin as NSDate)
    }
    
    // Agrupa los logs por actividad y suma el tiempo
    func agruparDatos(activityItems: [ActivityItem], logsOfDay: [ActivityLog]) -> [(item: ActivityItem, totalTime: Int64)] {
        let agrupado = Dictionary(grouping: logsOfDay, by: { $0.idActivityItem ?? UUID() })
        return agrupado.compactMap { (clave, logs) in
            guard let item = activityItems.first(where: { $0.id == clave }) else { return nil }
            let total = logs.reduce(0) { $0 + $1.timeSpent }
            return (item: item, totalTime: total)
        }
    }
    
    // Cálculos de totales y porcentajes
    func totalTracked(datosAgrupados: [(item: ActivityItem, totalTime: Int64)]) -> Double {
        return Double(datosAgrupados.reduce(0) { $0 + $1.totalTime })
    }
    
    func untracked(totalTracked: Double) -> Double {
        return max(secondsInDay - totalTracked, 0)
    }
    
    func trackedPercent(totalTracked: Double) -> Double {
        return totalTracked / secondsInDay
    }
    
    func untrackedPercent(untracked: Double) -> Double {
        return untracked / secondsInDay
    }
    
    // Funciones de formateo
    func formatTime(seconds: Double) -> String {
        let intSeconds = Int(seconds)
        let hours = intSeconds / 3600
        let minutes = (intSeconds % 3600) / 60
        let secs = intSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
    
    func formatPercent(_ value: Double) -> String {
        return String(format: "%.0f", value * 100)
    }
    
    // Datos para el gráfico de pastel
    func pieData(datosAgrupados: [(item: ActivityItem, totalTime: Int64)], totalTracked: Double) -> [PieSliceData] {
        var slices: [PieSliceData] = datosAgrupados.map { entry in
            PieSliceData(
                value: Double(entry.totalTime) / secondsInDay,
                color: Color(hex: entry.item.wrappedColor),
                label: entry.item.name ?? "Actividad"
            )
        }
        let untrackedValue = untracked(totalTracked: totalTracked)
        if untrackedValue > 0 {
            slices.append(
                PieSliceData(
                    value: untrackedValue / secondsInDay,
                    color: Color.gray.opacity(0.3),
                    label: "Sin actividad"
                )
            )
        }
        return slices
    }
}
