//
//  ActivityTimerView.swift
//  ActiTracker
//
//  Created by Julian David Rodriguez on 24/03/25.
//

import SwiftUI
import CoreData

struct ActivityTimerView: View {
    @FetchRequest(
        entity: ActivityItem.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ActivityItem.name, ascending: true)]
    )
    private var activities: FetchedResults<ActivityItem>
    
    @StateObject private var viewModel: ActivityTimerViewModel
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: ActivityTimerViewModel(context: context))
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                heroCard
                selectionSection
                summarySection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(backgroundView.ignoresSafeArea())
        .onAppear {
            if !viewModel.hasActiveSession,
               viewModel.selectedActivity == nil,
               let first = activities.first {
                viewModel.select(activity: first)
            }
        }
    }
    
    private var heroCard: some View {
        let accent = Color(hex: viewModel.selectedActivity?.wrappedColor ?? "111827")
        
        return ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            accent.opacity(0.92),
                            accent.opacity(0.55),
                            Color.black.opacity(0.94)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(.white.opacity(0.15), lineWidth: 1)
            
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("timer_header")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                        Text(statusSubtitle)
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(.white.opacity(0.72))
                    }
                    Spacer()
                    statusBadge
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(viewModel.formattedTime)
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.75)
                    
                    if let activity = viewModel.selectedActivity {
                        HStack(spacing: 10) {
                            ColorCircleView(hex: activity.wrappedColor, width: 14, height: 14)
                            Text(activity.name ?? "Sin actividad")
                                .font(.system(.headline, design: .rounded, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.92))
                                .lineLimit(1)
                        }
                    }
                }
                
                actionRow
            }
            .padding(24)
        }
        .shadow(color: accent.opacity(0.2), radius: 24, y: 18)
    }
    
    private var selectionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(viewModel.hasActiveSession ? "Actividad actual" : "Elige una actividad")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.85))
            
            if activities.isEmpty {
                emptyStateCard
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(activities) { activity in
                            ActivityChip(
                                activity: activity,
                                isSelected: viewModel.selectedActivity?.id == activity.id,
                                isLocked: viewModel.hasActiveSession
                            ) {
                                viewModel.select(activity: activity)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Hoy")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                Spacer()
                Text("\(activities.count) actividades")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            
            ListActivitiesTimer(activities: activities, viewModel: viewModel) { activity in
                viewModel.select(activity: activity)
            }
        }
    }
    
    private var statusBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusTitle)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.white.opacity(0.14), in: Capsule())
    }
    
    private var actionRow: some View {
        HStack(spacing: 12) {
            if viewModel.status == .idle {
                ActionButton(
                    title: "Iniciar",
                    systemImage: "play.fill",
                    tint: .white,
                    foreground: .black,
                    isProminent: true
                ) {
                    viewModel.startTimer()
                }
                .disabled(viewModel.selectedActivity == nil)
            } else if viewModel.status == .running {
                ActionButton(
                    title: "Pausar",
                    systemImage: "pause.fill",
                    tint: .white.opacity(0.16),
                    foreground: .white,
                    isProminent: false
                ) {
                    viewModel.pauseTimer()
                }
                ActionButton(
                    title: "Detener",
                    systemImage: "stop.fill",
                    tint: Color.white,
                    foreground: Color.red.opacity(0.88),
                    isProminent: true
                ) {
                    viewModel.stopTimer()
                }
            } else {
                ActionButton(
                    title: "Reanudar",
                    systemImage: "play.fill",
                    tint: .white,
                    foreground: .black,
                    isProminent: true
                ) {
                    viewModel.resumeTimer()
                }
                ActionButton(
                    title: "Detener",
                    systemImage: "stop.fill",
                    tint: .white.opacity(0.16),
                    foreground: .white,
                    isProminent: false
                ) {
                    viewModel.stopTimer()
                }
            }
        }
    }
    
    private var emptyStateCard: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color.white.opacity(0.9))
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("Crea tu primera actividad para comenzar a medir tu tiempo.")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.vertical, 28)
            }
    }
    
    private var backgroundView: some View {
        ZStack {
            Color(red: 0.96, green: 0.97, blue: 0.99)
            Circle()
                .fill(Color.black.opacity(0.05))
                .frame(width: 320)
                .blur(radius: 12)
                .offset(x: 140, y: -220)
            Circle()
                .fill(Color.blue.opacity(0.08))
                .frame(width: 260)
                .blur(radius: 20)
                .offset(x: -140, y: -180)
            Circle()
                .fill(Color(hex: viewModel.selectedActivity?.wrappedColor ?? "94A3B8").opacity(0.12))
                .frame(width: 280)
                .blur(radius: 30)
                .offset(x: 130, y: 220)
        }
    }
    
    private var statusTitle: String {
        switch viewModel.status {
        case .idle:
            return "Listo"
        case .running:
            return "En curso"
        case .paused:
            return "En pausa"
        }
    }
    
    private var statusSubtitle: String {
        switch viewModel.status {
        case .idle:
            return "Selecciona una actividad y empieza a medir el tiempo."
        case .running:
            return "Tu Live Activity sigue el avance y ahora también puede pausar o detener."
        case .paused:
            return "Puedes reanudar la sesión o detenerla desde aquí o desde la actividad."
        }
    }
    
    private var statusColor: Color {
        switch viewModel.status {
        case .idle:
            return .white.opacity(0.9)
        case .running:
            return Color.green.opacity(0.95)
        case .paused:
            return Color.orange.opacity(0.95)
        }
    }
}

private struct ActionButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    let foreground: Color
    let isProminent: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(tint, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                if !isProminent {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                }
            }
            .foregroundStyle(foreground)
        }
        .buttonStyle(.plain)
    }
}

private struct ActivityChip: View {
    let activity: ActivityItem
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ColorCircleView(hex: activity.wrappedColor, width: 12, height: 12)
                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.name ?? "Sin nombre")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .lineLimit(1)
                    Text(isSelected ? "Seleccionada" : "Disponible")
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.black.opacity(0.65) : .secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
        .opacity(isLocked && !isSelected ? 0.55 : 1)
    }
    
    private var background: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(hex: activity.wrappedColor).opacity(0.26),
                        .white
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        
        return AnyShapeStyle(Color.white.opacity(0.92))
    }
    
    private var borderColor: Color {
        isSelected ? Color(hex: activity.wrappedColor).opacity(0.45) : .black.opacity(0.06)
    }
}

#Preview {
    ActivityTimerView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
