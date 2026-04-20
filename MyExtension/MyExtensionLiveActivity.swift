//
//  MyExtensionLiveActivity.swift
//  MyExtension
//
//  Created by Julian David Rodriguez on 24/03/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

@main
struct MyExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ActivitiesAttributes.self) { context in
            LockScreenActivityView(state: context.state)
                .activityBackgroundTint(.clear)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    ActivityCompactBadge(colorHex: context.state.colorHex)
                }
                DynamicIslandExpandedRegion(.center) {
                    ExpandedActivitySummary(state: context.state)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ExpandedActivityActions(state: context.state)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedActivityFooter(state: context.state)
                }
            } compactLeading: {
                ActivityCompactBadge(colorHex: context.state.colorHex, size: 10, prominence: .subtle)
            } compactTrailing: {
                HStack(spacing: 5) {
                    Image(systemName: context.state.isRunning ? "clock.fill" : "pause.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.68))
                    LiveActivityTimerText(state: context.state, style: .compact)
                }
                .frame(minWidth: 54, alignment: .trailing)
            } minimal: {
                MinimalActivityView(state: context.state)
            }
            .keylineTint(.clear)
        }
    }
}

private struct LockScreenActivityView: View {
    let state: ActivitiesAttributes.ContentState
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ActivityCompactBadge(colorHex: state.colorHex, size: 14, prominence: .regular)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(state.name)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .lineLimit(1)
                        .foregroundStyle(.white)
                    StatusCapsule(state: state)
                }
                
                LiveActivityTimerText(state: state, style: .lockScreen)
            }
            
            Spacer(minLength: 8)
            ActivityButtons(state: state, axis: .horizontal)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(lockScreenBackground)
        .padding(.vertical, 8)
    }
    
    private var lockScreenBackground: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(Color.black.opacity(0.88))
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: state.colorHex).opacity(0.28),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            }
    }
}

private struct ExpandedActivitySummary: View {
    let state: ActivitiesAttributes.ContentState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(state.name)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .lineLimit(1)
            LiveActivityTimerText(state: state, style: .expanded)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ExpandedActivityActions: View {
    let state: ActivitiesAttributes.ContentState
    
    var body: some View {
        ActivityButtons(state: state, axis: .vertical)
    }
}

private struct ExpandedActivityFooter: View {
    let state: ActivitiesAttributes.ContentState
    
    var body: some View {
        HStack {
            StatusCapsule(state: state)
            Spacer()
            Text(state.isRunning ? "Controla la sesión desde aquí" : "La actividad está pausada")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }
}

private struct MinimalActivityView: View {
    let state: ActivitiesAttributes.ContentState
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: state.colorHex).opacity(0.12))
            Image(systemName: state.isRunning ? "pause.fill" : "play.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color(hex: state.colorHex))
        }
        .frame(width: 24, height: 24)
    }
}

private struct ActivityButtons: View {
    let state: ActivitiesAttributes.ContentState
    let axis: Axis
    
    var body: some View {
        Group {
            if axis == .horizontal {
                HStack(spacing: 8) {
                    primaryButton
                    stopButton
                }
            } else {
                VStack(spacing: 8) {
                    primaryButton
                    stopButton
                }
            }
        }
    }
    
    private var primaryButton: some View {
        Group {
            if state.isRunning {
                Button(intent: PauseActivityIntent()) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 13, weight: .bold))
                        .frame(width: 34, height: 34)
                        .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            } else {
                Button(intent: ResumeActivityIntent()) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 13, weight: .bold))
                        .frame(width: 34, height: 34)
                        .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private var stopButton: some View {
        Button(intent: StopActivityIntent()) {
            Image(systemName: "stop.fill")
                .font(.system(size: 12, weight: .black))
                .frame(width: 34, height: 34)
                .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .foregroundStyle(Color.red.opacity(0.9))
        }
        .buttonStyle(.plain)
    }
}

private struct ActivityCompactBadge: View {
    enum Prominence {
        case regular
        case subtle
    }
    
    let colorHex: String
    var size: CGFloat = 14
    var prominence: Prominence = .regular
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: colorHex).opacity(prominence == .regular ? 0.18 : 0.08))
            if prominence == .regular {
                Circle()
                    .fill(Color(hex: colorHex))
                    .frame(width: size, height: size)
            } else {
                Circle()
                    .fill(Color(hex: colorHex).opacity(0.88))
                    .frame(width: size, height: size)
            }
        }
        .frame(width: size + (prominence == .regular ? 14 : 10), height: size + (prominence == .regular ? 14 : 10))
    }
}

private struct StatusCapsule: View {
    let state: ActivitiesAttributes.ContentState
    
    var body: some View {
        Text(state.isRunning ? "EN CURSO" : "PAUSA")
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .kerning(0.8)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.white.opacity(state.isRunning ? 0.16 : 0.22), in: Capsule())
    }
}

private struct LiveActivityTimerText: View {
    enum DisplayStyle {
        case lockScreen
        case expanded
        case compact
    }
    
    let state: ActivitiesAttributes.ContentState
    let style: DisplayStyle
    
    var body: some View {
        Group {
            if state.isRunning, let timerStartDate = state.timerStartDate {
                if style == .compact {
                    Text(
                        timerInterval: timerStartDate...Date.distantFuture,
                        pauseTime: nil,
                        countsDown: false,
                        showsHours: state.elapsedTime >= 3600
                    )
                } else {
                    Text(timerStartDate, style: .timer)
                }
            } else {
                Text(formattedTime(state.elapsedTime))
            }
        }
        .font(font)
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .foregroundStyle(.white)
    }
    
    private var font: Font {
        switch style {
        case .lockScreen:
            return .system(size: 28, weight: .black, design: .rounded)
        case .expanded:
            return .system(.title3, design: .rounded, weight: .bold)
        case .compact:
            return .system(size: 14, weight: .bold, design: .rounded)
        }
    }
    
    private func formattedTime(_ seconds: TimeInterval) -> String {
        let intSeconds = Int(seconds)
        let hours = intSeconds / 3600
        let minutes = (intSeconds % 3600) / 60
        let secs = intSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
}

struct MyExtensionLiveActivity_Previews: PreviewProvider {
    static let attributes = ActivitiesAttributes()
    static let content = ActivitiesAttributes.ContentState(
        name: "Programacion",
        colorHex: "FF5A36",
        elapsedTime: 1000,
        timerStartDate: Date().addingTimeInterval(-1000),
        isRunning: true
    )
    
    static var previews: some View {
        attributes.previewContext(content, viewKind: .content)
            .previewDisplayName("Content")
        attributes.previewContext(content, viewKind: .dynamicIsland(.compact))
            .previewDisplayName("Compact")
        attributes.previewContext(content, viewKind: .dynamicIsland(.expanded))
            .previewDisplayName("Expanded")
        attributes.previewContext(content, viewKind: .dynamicIsland(.minimal))
            .previewDisplayName("Minimal")
    }
}
