//
//  ActivityTimerView.swift
//  ActiTracker
//
//  Created by Julian David Rodriguez on 24/03/25.
//

import SwiftUI
import CoreData

struct ActivityTimerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // Lista de actividades obtenidas desde Core Data.
    @FetchRequest(
        entity: ActivityItem.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ActivityItem.name, ascending: true)]
    )
    
    private var activities: FetchedResults<ActivityItem>
    
    // Instanciamos el ViewModel y lo inyectamos con el managedObjectContext.
    @StateObject private var viewModel: ActivityTimerViewModel
    
    // Inicializador personalizado para pasar el contexto al ViewModel.
    init() {
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: ActivityTimerViewModel(context: context))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("timer_header")
                .font(.title)
                .fontWeight(.bold)
            Text("timer_subtitle")
                .font(.subheadline)
                .fontWeight(.light)
            
            VStack(spacing: 20) {
                Text(viewModel.formattedTime)
                    .font(.system(size: 50, design: .monospaced))
                    .fontWeight(.bold)
                
                if viewModel.isTimerRunning {
                    HStack(spacing: 8) {
                        ColorCircleView(hex: viewModel.selectedActivity?.wrappedColor ?? "")
                        Text(viewModel.selectedActivity?.name ?? "Sin actividad")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .padding(10)
                    .background(.regularMaterial.shadow(.drop(color: .black.opacity(0.15), radius: 20, y: 10)), in: .capsule)
                    .cornerRadius(12)
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
                } else {
                    Text("timer_subtitle_timer")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 20) {
                    if !viewModel.isTimerRunning {
                        Picker("timer_label_picker", selection: $viewModel.selectedActivity) {
                            ForEach(activities) { activity in
                                HStack {
                                    ColorCircleView(hex: activity.wrappedColor)
                                    Text(activity.name ?? "Sin nombre")
                                }
                                .tag(activity as ActivityItem?)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                    }
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                            viewModel.toggleTimer()
                        }
                    }) {
                        Text(viewModel.isTimerRunning ? "timer_stop" : "timer_start")
                            .padding()
                            .frame(maxWidth: viewModel.isTimerRunning ? .infinity : 100)
                            .background(viewModel.isTimerRunning ? Color.red : Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .frame(height: 250)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray, lineWidth: 1)
            )
            
            ListActivitiesTimer(activities: activities, viewModel: viewModel)
            
            Spacer()
        }
        .padding()
        .onAppear {
            if viewModel.selectedActivity == nil, let first = activities.first {
                viewModel.selectedActivity = first
            }
        }
    }
}

#Preview {
    ActivityTimerView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
