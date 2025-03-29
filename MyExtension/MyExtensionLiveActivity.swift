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
            // Vista para pantalla de bloqueo/banner: muestra círculo, nombre y el contador
            HStack {
                Circle()
                    .fill(Color(hex: context.state.colorHex))
                    .frame(width: 20, height: 20)
                    .padding(3)
                    .padding(.leading, 16)
                Text(context.state.name)
                    .bold()
                Spacer()
                // Se muestra el contador usando el valor actualizado (baseTime)
                LiveActivityTimerView(baseTime: context.state.baseTime)
                    .padding(.trailing, 12)
            }
            
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Circle()
                        .fill(Color(hex: context.state.colorHex))
                        .frame(width: 20, height: 20)
                        .padding(3)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    // Muestra el contador en la región derecha
                    LiveActivityTimerView(baseTime: context.state.baseTime)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.name)
                }
            } compactLeading: {
                Circle()
                    .fill(Color(hex: context.state.colorHex))
                    .frame(width: 20, height: 20)
                    .padding(3)
            } compactTrailing: {
                // Muestra el contador en la versión compacta
                LiveActivityTimerView(baseTime: context.state.baseTime)
            } minimal: {
                Circle()
                    .fill(Color(hex: context.state.colorHex))
                    .frame(width: 20, height: 20)
                    .padding(3)
            }
        }
    }
}

struct MyExtensionLiveActivity_Previews: PreviewProvider {
    static let attributes = ActivitiesAttributes()
    static let content = ActivitiesAttributes.ContentState(baseTime: 1000, name: "Programacion", colorHex: "FF0000")
    
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

struct LiveActivityTimerView: View {
    let baseTime: TimeInterval
    
    var body: some View {
        // Simplemente se muestra el tiempo formateado según el valor baseTime actualizado desde la app principal.
        Text(formattedTime(baseTime))
            .font(.headline)
    }
    
    private func formattedTime(_ seconds: TimeInterval) -> String {
        let intSeconds = Int(seconds)
        let hours = intSeconds / 3600
        let minutes = (intSeconds % 3600) / 60
        let secs = intSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
}
