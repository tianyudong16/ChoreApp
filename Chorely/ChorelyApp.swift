//
//  ChorelyApp.swift
//  Chorely
//
//  Created by Tian Yu Dong on 10/29/25.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
  }
}
//var ref: DatabaseReference! This line of code isn't working, putting this aside for now because it's late

//ref = Database.database().reference()

@main
struct ChorelyApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
