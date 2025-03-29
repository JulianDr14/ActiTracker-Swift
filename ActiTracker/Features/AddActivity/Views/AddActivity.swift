//
//  ContentView.swift
//  ActiTracker
//
//  Created by Julian David Rodriguez on 23/03/25.
//

import SwiftUI
import CoreData

struct AddActivity: View {
    // Obtenemos el contexto de Core Data del entorno.
    @Environment(\.managedObjectContext) private var viewContext
    
    // Usamos @FetchRequest para obtener las actividades guardadas en Core Data.
    @FetchRequest(
        entity: ActivityItem.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ActivityItem.name, ascending: true)]
    ) private var activities: FetchedResults<ActivityItem>
    
    @State private var taskName: String = ""
    @State private var selectedColor: String = "FF0000"
    
    let colors = ["FF0000", "E97A35", "E9A13B", "94CA43", "55B685", "52B4D1", "4E82EE", "8461EE", "C954E8"]
    
    // Binding intermedio que convierte entre String (hex) y Color.
    var bindingColor: Binding<Color> {
        Binding<Color>(
            get: {
                Color(hex: selectedColor)
            },
            set: { newColor in
                let uiColor = UIColor(newColor)
                var red: CGFloat = 0
                var green: CGFloat = 0
                var blue: CGFloat = 0
                var alpha: CGFloat = 0
                if uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
                    selectedColor = String(format: "%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
                }
            }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("add_new_activity")
                .font(.title)
            
            VStack(alignment: .leading) {
                Text("add_activity_name")
                    .font(.subheadline)
                TextField("add_hint_text", text: $taskName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(alignment: .leading) {
                Text("add_color")
                    .font(.subheadline)
                HStack {
                    ForEach(colors, id: \.self) { color in
                        ColorButton(
                            selectedColor: color,
                            isSelected: selectedColor == color,
                            action: {
                                selectedColor = color
                            }
                        )
                    }
                    ColorPicker("add_label_picker", selection: bindingColor)
                        .labelsHidden()
                }
            }
            
            Button(action: {
                addActivity()
                // Se oculta el teclado si es necesario.
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("add_label_button")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            
            Text("add_your_activities")
                .font(.title3)
            
            // Se llama a la nueva vista que muestra las actividades desde Core Data
            ListActivities(activities: activities, context: viewContext)
            
            Spacer()
        }
        .padding()
    }
    
    // Función para agregar una nueva actividad a Core Data.
    private func addActivity() {
        guard !taskName.isEmpty else { return }
        
        let newActivity = ActivityItem(context: viewContext)
        newActivity.id = UUID()
        newActivity.name = taskName
        newActivity.color = selectedColor
        
        do {
            try viewContext.save()
            taskName = ""
        } catch {
            print("Error al guardar la actividad: \(error.localizedDescription)")
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        AddActivity().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
#endif
