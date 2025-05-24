//
//  WelcomeView.swift
//  Habita
//
//  Created by Hubert on 19/05/2025.
//

import SwiftUI
import CoreData

struct WelcomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: User.entity(), sortDescriptors: []) private var users: FetchedResults<User>
    
    @State private var name: String = ""
    @State private var surname: String = ""
    @State private var age: String = ""
    @State private var gender: String = "Male"
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let genders = ["Male", "Female", "Other"]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(spacing: 16) {
                        Image("welcome")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 320)
                        
                        Text("Welcome to Habita!")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Text("Please enter your details to get started")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                .padding(.top, 16)
                
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
                    ModernYellowButton(action: saveUserData, title: "Continue")
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Setup")
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
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("❌ Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func saveUserData() {
        guard !name.isEmpty else {
            alertMessage = "Please enter your name"
            showingAlert = true
            return
        }
        
        guard !surname.isEmpty else {
            alertMessage = "Please enter your surname"
            showingAlert = true
            return
        }
        
        guard let ageValue = Int16(age), ageValue > 0 else {
            alertMessage = "Please enter a valid age"
            showingAlert = true
            return
        }
        
        let user = User(context: viewContext)
        user.name = name
        user.surname = surname
        user.age = ageValue
        user.gender = gender
        
        do {
            try viewContext.save()
        } catch {
            alertMessage = "Failed to save user data"
            showingAlert = true
            print("Failed to save user: \(error)")
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
                    .foregroundColor(.black)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(
                        Capsule()
                            .fill(Color.yellow)
                    )
                    .scaleEffect(isPressed ? 0.95 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
