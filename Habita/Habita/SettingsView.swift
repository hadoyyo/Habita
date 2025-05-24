//
//  SettingsView.swift
//  Habita
//
//  Created by Hubert on 19/05/2025.
//

import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: User.entity(), sortDescriptors: []) private var users: FetchedResults<User>
    
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @State private var name: String = ""
    @State private var surname: String = ""
    @State private var age: String = ""
    @State private var gender: String = "Male"
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    let genders = ["Male", "Female", "Other"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $darkModeEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: .yellow))
                        .onChange(of: darkModeEnabled) {
                            updateAppearance()
                        }
                }
                
                Section(header: Text("Personal Information")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("First Name")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("Enter your first name", text: $name)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last Name")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("Enter your last name", text: $surname)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Age")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("Enter your age", text: $age)
                            .keyboardType(.numberPad)
                    }
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Gender")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Picker("Select gender", selection: $gender) {
                            ForEach(genders, id: \.self) {
                                Text($0)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .accentColor(.yellow)
                    }
                }
                
                Section {
                    ModernYellowButton(action: updateUserData, title: "Save Changes")
                }
                .listRowBackground(Color.clear)
            }
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        HStack(spacing: 2) {
                            Image("logo")
                                .resizable()
                                .renderingMode(.template)
                                .interpolation(.high)
                                .antialiased(true)
                                .scaledToFit()
                                .frame(width: 25, height: 25)
                                .foregroundColor(.yellow)
                            
                            Text("Habita")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .alert(isPresented: $showingAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                if let user = users.first {
                    name = user.name ?? ""
                    surname = user.surname ?? ""
                    age = String(user.age)
                    gender = user.gender ?? "Male"
                }
            }
        }
        .preferredColorScheme(darkModeEnabled ? .dark : .light)
    }
    
    private func updateUserData() {
        guard !name.isEmpty else {
            alertTitle = "❌ Error"
            alertMessage = "Please enter your name"
            showingAlert = true
            return
        }
        
        guard !surname.isEmpty else {
            alertTitle = "❌ Error"
            alertMessage = "Please enter your surname"
            showingAlert = true
            return
        }
        
        guard let ageValue = Int16(age), ageValue > 0 else {
            alertTitle = "❌ Error"
            alertMessage = "Please enter a valid age"
            showingAlert = true
            return
        }
        
        if let user = users.first {
            user.name = name
            user.surname = surname
            user.age = ageValue
            user.gender = gender
            
            do {
                try viewContext.save()
                alertTitle = "✔️ Success"
                alertMessage = "Changes saved successfully"
                showingAlert = true
            } catch {
                alertTitle = "❌ Error"
                alertMessage = "Failed to save changes"
                showingAlert = true
                print("Failed to update user: \(error)")
            }
        }
    }
    
    private func updateAppearance() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = darkModeEnabled ? .dark : .light
            }
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

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
