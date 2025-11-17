//
//  ChorelyApp.swift
//  Chorely
//
//  Created by Tian Yu Dong on 10/29/25.
//

import SwiftUI

@main
struct ChorelyApp: App {
    init() {
        _ = FirebaseInterface.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
