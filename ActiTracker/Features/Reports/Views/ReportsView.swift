//
//  ReportsView.swift
//  ActiTracker
//
//  Created by Julian David Rodriguez on 24/03/25.
//

import SwiftUI
import CoreData

struct ReportsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @StateObject private var viewModel = ReportsViewModel()
    
    @FetchRequest(entity: ActivityItem.entity(), sortDescriptors: []) var activityItems: FetchedResults<ActivityItem>
    @FetchRequest private var logsOfDay: FetchedResults<ActivityLog>
    
    private let secondsInDay: Double = 86400
    
    init() {
        let calendar = Calendar.current
        let inicio = calendar.startOfDay(for: Date())
        let fin = calendar.date(byAdding: .day, value: 1, to: inicio)!
        let predicate = NSPredicate(format: "date >= %@ AND date < %@", inicio as NSDate, fin as NSDate)
        _logsOfDay = FetchRequest(
            entity: ActivityLog.entity(),
            sortDescriptors: [],
            predicate: predicate
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Selector de fecha
                HStack {
                    Spacer()
                    DatePicker("repor_label_date", selection: $viewModel.selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .onChange(of: viewModel.selectedDate) { newValue, transaction in
                            logsOfDay.nsPredicate = viewModel.logsPredicate
                        }
                }
                
                // Obtención de datos a través del view model
                let datosAgrupados = viewModel.agruparDatos(activityItems: Array(activityItems), logsOfDay: Array(logsOfDay))
                let totalTracked = viewModel.totalTracked(datosAgrupados: datosAgrupados)
                let untracked = viewModel.untracked(totalTracked: totalTracked)
                let trackedPercent = viewModel.trackedPercent(totalTracked: totalTracked)
                let untrackedPercent = viewModel.untrackedPercent(untracked: untracked)
                let slices = viewModel.pieData(datosAgrupados: datosAgrupados, totalTracked: totalTracked)
                
                // Uso de los componentes separados
                SummarySectionView(totalTracked: totalTracked,
                                   trackedPercent: trackedPercent,
                                   untracked: untracked,
                                   untrackedPercent: untrackedPercent,
                                   formatTime: viewModel.formatTime,
                                   formatPercent: viewModel.formatPercent)
                
                TimeDistributionSectionView(slices: slices)
                
                ActivityBreakdownSectionView(datosAgrupados: datosAgrupados,
                                             totalTracked: totalTracked,
                                             formatTime: viewModel.formatTime,
                                             formatPercent: viewModel.formatPercent)
                
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    ReportsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
