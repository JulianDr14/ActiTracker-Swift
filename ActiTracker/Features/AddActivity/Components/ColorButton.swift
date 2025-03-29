//
//  ColorButton.swift
//  ActiTracker
//
//  Created by Julian David Rodriguez on 23/03/25.
//

import SwiftUI

struct ColorButton: View {
    var selectedColor: String
    var isSelected: Bool = false
    var action: () -> Void = {}
    
    var body: some View {
        Button(action: {
            action()
        }) {
            Circle()
                .fill(Color(hex: selectedColor))
                .frame(width: 20, height: 20)
                .padding(3)
                .background(
                    Circle().stroke(isSelected ? Color.black : Color.clear, lineWidth: 1)
                )
        }
    }
}
