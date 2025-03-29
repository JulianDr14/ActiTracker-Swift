//
//  ColorCircleView.swift
//  ActiTracker
//
//  Created by Julian David Rodriguez on 29/03/25.
//

import SwiftUI

struct ColorCircleView: View {
    let hex: String
    
    
    var body: some View {
        Circle()
            .fill(Color(hex: hex))
            .frame(width: 20, height: 20)
    }
}

#Preview {
    ColorCircleView(
        hex: "FF0000"
    )
}
