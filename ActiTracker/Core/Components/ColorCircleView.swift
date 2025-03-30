//
//  ColorCircleView.swift
//  ActiTracker
//
//  Created by Julian David Rodriguez on 29/03/25.
//

import SwiftUI

struct ColorCircleView: View {
    let hex: String
    let width: CGFloat
    let height: CGFloat
    
    init(hex: String, width: CGFloat = 20, height: CGFloat = 20) {
        self.hex = hex
        self.width = width
        self.height = height
    }
    
    
    var body: some View {
        Circle()
            .fill(Color(hex: hex))
            .frame(width: width, height: height)
    }
}

#Preview {
    ColorCircleView(
        hex: "FF0000"
    )
}
