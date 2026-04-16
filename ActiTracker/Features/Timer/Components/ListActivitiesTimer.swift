//
//  ListActivitiesTimer.swift
//  ActiTracker
//
//  Created by Julian David Rodriguez on 29/03/25.
//

import SwiftUI

struct ListActivitiesTimer: View {
    var activities: FetchedResults<ActivityItem>
    @ObservedObject var viewModel: ActivityTimerViewModel
    var onSelect: (ActivityItem) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(activities, id: \.id) { activity in
                Button {
                    onSelect(activity)
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: activity.wrappedColor).opacity(0.14))
                                .frame(width: 42, height: 42)
                            ColorCircleView(hex: activity.wrappedColor, width: 16, height: 16)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(activity.name ?? "Sin nombre")
                                .font(.system(.headline, design: .rounded, weight: .bold))
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(subtitle(for: activity))
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        
                        Text(viewModel.formattedTotalTime(for: activity))
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.primary)
                    }
                    .padding(16)
                    .background(background(for: activity), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(border(for: activity), lineWidth: 1)
                    }
                    .shadow(color: shadow(for: activity), radius: 14, y: 10)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.hasActiveSession)
                .opacity(viewModel.hasActiveSession && viewModel.selectedActivity?.id != activity.id ? 0.75 : 1)
            }
        }
    }
    
    private func subtitle(for activity: ActivityItem) -> String {
        if viewModel.selectedActivity?.id == activity.id {
            if viewModel.isTimerRunning {
                return "Sesión activa"
            }
            if viewModel.isTimerPaused {
                return "Sesión en pausa"
            }
            return "Actividad seleccionada"
        }
        
        return "Tiempo acumulado hoy"
    }
    
    private func background(for activity: ActivityItem) -> some ShapeStyle {
        if viewModel.selectedActivity?.id == activity.id {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(hex: activity.wrappedColor).opacity(0.22),
                        Color.white
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        
        return AnyShapeStyle(Color.white.opacity(0.95))
    }
    
    private func border(for activity: ActivityItem) -> Color {
        if viewModel.selectedActivity?.id == activity.id {
            return Color(hex: activity.wrappedColor).opacity(0.4)
        }
        
        return .black.opacity(0.05)
    }
    
    private func shadow(for activity: ActivityItem) -> Color {
        if viewModel.selectedActivity?.id == activity.id {
            return Color(hex: activity.wrappedColor).opacity(0.16)
        }
        
        return .black.opacity(0.04)
    }
}
