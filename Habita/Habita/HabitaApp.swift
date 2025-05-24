//
//  HabitaApp.swift
//  Habita
//
//  Created by Hubert on 19/05/2025.
//

import SwiftUI

@main
struct HabitaApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
