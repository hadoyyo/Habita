//
//  ContentView.swift
//  Habita
//
//  Created by Hubert on 19/05/2025.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: User.entity(), sortDescriptors: []) private var users: FetchedResults<User>
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    
    var body: some View {
        if users.isEmpty {
            WelcomeView()
                .preferredColorScheme(darkModeEnabled ? .dark : .light)
                .environment(\.managedObjectContext, viewContext)
        } else {
            MainTabView()
                .preferredColorScheme(darkModeEnabled ? .dark : .light)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
