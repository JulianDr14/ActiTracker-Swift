//
//  PieChartView.swift
//  ActiTracker
//
//  Created by Julian David Rodriguez on 24/03/25.
//

import SwiftUI

// Datos para cada porción del pastel
struct PieSliceData {
    var value: Double
    var color: Color
    var label: String
}

// Shape que dibuja una porción (arco) del pastel
struct PieSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.move(to: center)
        path.addArc(center: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false)
        path.closeSubpath()
        return path
    }
}

// Vista que construye el diagrama de pastel
struct PieChartView: View {
    var slices: [PieSliceData]
    
    // Suma total de los valores
    var total: Double {
        slices.reduce(0) { $0 + $1.value }
    }
    
    // Calcula los ángulos para cada slice
    private func angles() -> [Angle] {
        var angles: [Angle] = []
        var currentAngle = -90.0 // Comienza en la parte superior
        angles.append(Angle(degrees: currentAngle))
        for slice in slices {
            currentAngle += (slice.value / total) * 360
            angles.append(Angle(degrees: currentAngle))
        }
        return angles
    }
    
    var body: some View {
        GeometryReader { geometry in
            let computedAngles = angles()
            ZStack {
                ForEach(0..<slices.count, id: \.self) { index in
                    PieSlice(startAngle: computedAngles[index],
                             endAngle: computedAngles[index + 1])
                        .fill(slices[index].color)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}
