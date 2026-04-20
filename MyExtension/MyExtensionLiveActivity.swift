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
                    ActivityDot(colorHex: context.state.colorHex, size: 12, ringSize: 36, cornerRadius: 10)
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
                ActivityDot(colorHex: context.state.colorHex, size: 8, ringSize: 20, cornerRadius: 10)
                    .padding(.leading, 2)
            } compactTrailing: {
                LiveActivityTimerText(state: context.state, style: .compact)
                    .frame(minWidth: 52, alignment: .trailing)
                    .padding(.trailing, 4)
            } minimal: {
                MinimalActivityView(state: context.state)
            }
            .keylineTint(.clear)
        }
    }
}

// MARK: - Lock Screen

private struct LockScreenActivityView: View {
    let state: ActivitiesAttributes.ContentState

    var body: some View {
        HStack(alignment: .center, spacing: 13) {
            ActivityDot(colorHex: state.colorHex, size: 14, ringSize: 42, cornerRadius: 12)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text(state.name)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .foregroundStyle(.white)
                    StatusPill(state: state)
                }
                LiveActivityTimerText(state: state, style: .lockScreen)
            }

            Spacer(minLength: 8)

            ActivityButtons(state: state, axis: .horizontal)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(lockScreenBackground)
        .padding(.vertical, 6)
    }

    private var lockScreenBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.black.opacity(0.9))
            .overlay(alignment: .leading) {
                // Subtle color bleed from the left
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: state.colorHex).opacity(0.20),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: UnitPoint(x: 0.6, y: 0.5)
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.07), lineWidth: 0.5)
            }
    }
}

// MARK: - Expanded Regions

private struct ExpandedActivitySummary: View {
    let state: ActivitiesAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(state.name)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .foregroundStyle(.white)
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
        HStack(spacing: 6) {
            StatusPill(state: state)
            Spacer()
            if !state.isRunning {
                Text("Actividad pausada")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .padding(.top, 2)
    }
}

// MARK: - Minimal

private struct MinimalActivityView: View {
    let state: ActivitiesAttributes.ContentState

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: state.colorHex).opacity(0.10))
            Image(systemName: state.isRunning ? "pause.fill" : "play.fill")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color(hex: state.colorHex))
        }
        .frame(width: 22, height: 22)
    }
}

// MARK: - Buttons

private struct ActivityButtons: View {
    let state: ActivitiesAttributes.ContentState
    let axis: Axis

    var body: some View {
        Group {
            if axis == .horizontal {
                HStack(spacing: 7) { primaryButton; stopButton }
            } else {
                VStack(spacing: 7) { primaryButton; stopButton }
            }
        }
    }

    private var primaryButton: some View {
        Group {
            if state.isRunning {
                Button(intent: PauseActivityIntent()) {
                    buttonIcon("pause.fill")
                        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            } else {
                Button(intent: ResumeActivityIntent()) {
                    buttonIcon("play.fill")
                        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var stopButton: some View {
        Button(intent: StopActivityIntent()) {
            buttonIcon("stop.fill", color: Color.red.opacity(0.85))
                .background(Color.red.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func buttonIcon(_ name: String, color: Color = .white) -> some View {
        Image(systemName: name)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(color)
            .frame(width: 32, height: 32)
    }
}

// MARK: - Activity Dot Badge

/// Minimal dot-in-ring badge. Replaces the old double-circle ActivityCompactBadge.
private struct ActivityDot: View {
    let colorHex: String
    var size: CGFloat = 10
    var ringSize: CGFloat = 24
    var cornerRadius: CGFloat = 10

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(hex: colorHex).opacity(0.14))
                .frame(width: ringSize, height: ringSize)
            Circle()
                .fill(Color(hex: colorHex))
                .frame(width: size, height: size)
        }
    }
}

// MARK: - Status Pill

private struct StatusPill: View {
    let state: ActivitiesAttributes.ContentState

    private var isRunning: Bool { state.isRunning }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isRunning ? Color(hex: state.colorHex) : Color.white.opacity(0.3))
                .frame(width: 5, height: 5)
            Text(isRunning ? "En curso" : "Pausa")
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .kerning(0.4)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(isRunning
                    ? Color(hex: state.colorHex).opacity(0.14)
                    : Color.white.opacity(0.08))
        )
        .foregroundStyle(isRunning ? Color(hex: state.colorHex) : Color.white.opacity(0.45))
    }
}

// MARK: - Timer Text

private struct LiveActivityTimerText: View {
    enum DisplayStyle { case lockScreen, expanded, compact }

    let state: ActivitiesAttributes.ContentState
    let style: DisplayStyle

    var body: some View {
        Group {
            if state.isRunning, let start = state.timerStartDate {
                if style == .compact {
                    Text(
                        timerInterval: start...Date.distantFuture,
                        pauseTime: nil,
                        countsDown: false,
                        showsHours: state.elapsedTime >= 3600
                    )
                } else {
                    Text(start, style: .timer)
                }
            } else {
                Text(formattedTime(state.elapsedTime))
            }
        }
        .font(font)
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .foregroundStyle(.white)
    }

    private var font: Font {
        switch style {
        case .lockScreen: return .system(size: 30, weight: .black, design: .rounded)
        case .expanded:   return .system(size: 18, weight: .bold,  design: .rounded)
        case .compact:    return .system(size: 13, weight: .bold,  design: .rounded)
        }
    }

    private func formattedTime(_ seconds: TimeInterval) -> String {
        let t = Int(seconds)
        return String(format: "%02d:%02d:%02d", t / 3600, (t % 3600) / 60, t % 60)
    }
}

// MARK: - Previews

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
            .previewDisplayName("Lock Screen")
        attributes.previewContext(content, viewKind: .dynamicIsland(.compact))
            .previewDisplayName("Compact")
        attributes.previewContext(content, viewKind: .dynamicIsland(.expanded))
            .previewDisplayName("Expanded")
        attributes.previewContext(content, viewKind: .dynamicIsland(.minimal))
            .previewDisplayName("Minimal")
    }
}
