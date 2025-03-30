//
//  AnimatedProgressBar.swift
//  ActiTracker
//
//  Created by Julian David Rodriguez on 30/03/25.
//

import SwiftUI

struct AnimatedProgressBar: View {
    /// Porcentaje final (valor entre 0 y 1) que se desea alcanzar.
    let targetProgress: Double
    /// Incremento en cada paso (por ejemplo, 0.01 equivale a 1%).
    let step: Double
    /// Intervalo en segundos entre cada incremento.
    let stepInterval: TimeInterval
    /// Color del progreso.
    let color: Color

    /// Variable de estado que guarda el progreso animado.
    @State private var animatedProgress: Double = 0.0
    
    init(targetProgress: Double, step: Double = 0.05, stepInterval: TimeInterval = 0.02, color: Color = .black) {
        self.targetProgress = targetProgress
        self.step = step
        self.stepInterval = stepInterval
        self.color = color
    }

    var body: some View {
        ProgressView(value: animatedProgress)
            .tint(color)
            .background(color.opacity(0.1))
            .onAppear {
                animatedProgress = 0.0
                Timer.scheduledTimer(withTimeInterval: stepInterval, repeats: true) { timer in
                    if animatedProgress < targetProgress {
                        animatedProgress = min(animatedProgress + step, targetProgress)
                    } else {
                        timer.invalidate()
                    }
                }
            }
    }
}

struct AnimatedProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        AnimatedProgressBar(
            targetProgress: 0.75,
            step: 0.05,
            stepInterval: 0.02,
            color: .blue
        )
        .padding()
    }
}
