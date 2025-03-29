//
//  SettingsView.swift
//  ActiTracker
//
//  Created by Julian David Rodriguez on 27/03/25.
//

import SwiftUI

struct SettingsView: View {
    @State var isVibrationEnabled: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("settings_header")
                .font(.title)
                .fontWeight(.bold)
            
            VStack {
                VStack {
                    Button(action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            if UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }) {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "gear")
                                    .frame(width: 24, alignment: .center)
                                Text("settings_change_language")
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                    }
                    Divider()
                    HStack {
                        Toggle(isOn: $isVibrationEnabled) {
                            HStack(spacing: 8) {
                                Image(systemName: "iphone.radiowaves.left.and.right")
                                    .frame(width: 24, alignment: .center)
                                VStack(alignment: .leading) {
                                    Text("Vibracion")
                                    Text("Habilitar vibracion")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
                .padding(8)
                .background(.regularMaterial)
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    SettingsView()
}
