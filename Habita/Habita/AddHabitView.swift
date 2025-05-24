//
//  AddHabitView.swift
//  Habita
//
//  Created by Hubert on 19/05/2025.
//

import SwiftUI
import CoreData

struct AddHabitView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    var habitToEdit: Habit?
    
    @State private var name: String = ""
    @State private var emoji: String = "🏃‍♂️"
    @State private var selectedType: HabitType = .quantitative
    @State private var targetValue: String = ""
    @State private var scaleRange: String = "10"
    @State private var selectedDays: [Int] = [1, 2, 3, 4, 5, 6, 7] // 1 = Monday, 7 = Sunday
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    
    init(habitToEdit: Habit? = nil) {
        self.habitToEdit = habitToEdit
        
        if let habit = habitToEdit {
            _name = State(initialValue: habit.name ?? "")
            _emoji = State(initialValue: habit.emoji ?? "🏃‍♂️")
            _selectedType = State(initialValue: HabitType(rawValue: habit.type ?? "") ?? .quantitative)
            _targetValue = State(initialValue: habit.targetValue > 0 ? String(habit.targetValue) : "")
            _scaleRange = State(initialValue: habit.scaleRange ?? "10")
            
            if let frequency = habit.frequency {
                // (1=Monday,...,7=Sunday)
                let rawDays = frequency
                    .components(separatedBy: ",")
                    .compactMap { Int($0) }
                    .map { $0 == 1 ? 7 : $0 - 1 }
                _selectedDays = State(initialValue: rawDays)
            }
        }
    }
    
    let emojis = ["🏃‍♂️", "💪", "📚", "🍎", "🚭", "🧘", "💧", "🛌", "✍️", "🧠"]
    let daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Info")) {
                    TextField("Habit Name", text: $name)
                    
                    Picker("Emoji", selection: $emoji) {
                        ForEach(emojis, id: \.self) { emoji in
                            Text(emoji).tag(emoji)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach(HabitType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(.yellow)
                                Text(type.rawValue)
                            }.tag(type)
                        }
                    }
                    .accentColor(.yellow)
                    .pickerStyle(MenuPickerStyle())
                }
                
                if selectedType == .qualitative {
                    Section(header: Text("Target Value")) {
                        TextField("Target quantity per day", text: $targetValue)
                            .keyboardType(.numberPad)
                            .onChange(of: targetValue) {
                                if let value = Int(targetValue), value == 0 {
                                    targetValue = ""
                                }
                            }
                    }
                } else if selectedType == .scalable {
                    Section(header: Text("Scale Range")) {
                        TextField("Maximum value (e.g., 10)", text: $scaleRange)
                            .keyboardType(.numberPad)
                            .onChange(of: scaleRange) {
                                if let value = Int(scaleRange), value == 0 {
                                    scaleRange = ""
                                }
                            }
                    }
                }
                
                Section(header: Text("Frequency")) {
                    ForEach(1...7, id: \.self) { day in
                        Button(action: {
                            toggleDay(day)
                        }) {
                            HStack {
                                Text(daysOfWeek[day - 1])
                                Spacer()
                                if selectedDays.contains(day) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                Section {
                    ModernYellowButton(action: saveHabit, title: habitToEdit == nil ? "Add Habit" : "Save Changes")
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle(habitToEdit == nil ? "New Habit" : "Edit Habit")
            .navigationBarItems(trailing: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Cancel")
                    .foregroundColor(.red)
            })
            .alert(isPresented: $showingValidationAlert) {
                Alert(title: Text("❌ Error"), message: Text(validationMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func toggleDay(_ day: Int) {
        if selectedDays.contains(day) {
            selectedDays.removeAll { $0 == day }
        } else {
            selectedDays.append(day)
        }
    }
    
    private func saveHabit() {
        guard !name.isEmpty else {
            validationMessage = "Please enter habit name"
            showingValidationAlert = true
            return
        }
        
        guard !selectedDays.isEmpty else {
            validationMessage = "Please select at least one day"
            showingValidationAlert = true
            return
        }
        
        if selectedType == .qualitative {
            guard !targetValue.isEmpty, let target = Int16(targetValue), target > 0 else {
                validationMessage = "Please enter a valid target value (greater than 0)"
                showingValidationAlert = true
                return
            }
        }
        
        if selectedType == .scalable {
            guard !scaleRange.isEmpty, let scale = Int(scaleRange), scale > 0 else {
                validationMessage = "Please enter a valid scale range (greater than 0)"
                showingValidationAlert = true
                return
            }
        }
        
        let habit: Habit
        if let habitToEdit = habitToEdit {
            habit = habitToEdit
        } else {
            habit = Habit(context: viewContext)
            habit.id = UUID()
            habit.createdAt = Date()
        }
        
        habit.name = name
        habit.emoji = emoji
        habit.type = selectedType.rawValue
        
        // (1=Sunday,...,7=Saturday)
        let mappedDays = selectedDays.map { $0 == 7 ? 1 : $0 + 1 }
        habit.frequency = mappedDays.map { String($0) }.joined(separator: ",")
        
        if selectedType == .qualitative, let target = Int16(targetValue) {
            habit.targetValue = target
        } else {
            habit.targetValue = 0
        }
        
        if selectedType == .scalable {
            habit.scaleRange = scaleRange
        } else {
            habit.scaleRange = nil
        }
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Failed to save habit: \(error)")
        }
    }
    
    struct ModernYellowButton: View {
        var action: () -> Void
        var title: String
        @State private var isPressed = false
        
        var body: some View {
            Button(action: {
                withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.4, blendDuration: 0.5)) {
                    isPressed = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.3, blendDuration: 1)) {
                        isPressed = false
                        action()
                    }
                }
            }) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.label))
                    .shadow(color: Color(.systemBackground).opacity(0.3), radius: 2, x: 0, y: 0)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(
                        Capsule()
                            .fill(Color.yellow)
                    )
                    .scaleEffect(isPressed ? 0.88 : 1.0)
                    .brightness(isPressed ? -0.1 : 0)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

struct AddHabitView_Previews: PreviewProvider {
    static var previews: some View {
        AddHabitView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
