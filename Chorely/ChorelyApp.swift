//
//  ChorelyApp.swift
//  Chorely
//
//  Created by Tian Yu Dong on 10/29/25.
//

import SwiftUI

//var ref: DatabaseReference! This line of code isn't working, putting this aside for now because it's late

//ref = Database.database().reference()

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
