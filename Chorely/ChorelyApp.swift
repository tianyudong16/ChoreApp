//
//  ChorelyApp.swift
//  Chorely
//
//  Created by Tian Yu Dong on 10/29/25.
//

import SwiftUI
import FirebaseCore

@main
struct ChorelyApp: App {
    
    // Ensures Firebase is initialized exactly once
    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("Firebase configured in ChorelyApp.swift")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
