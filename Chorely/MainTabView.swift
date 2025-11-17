//
//  MainTabView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 10/30/25.
//

// This file is to store all the different screens accessed through the task bar at the bottom


import SwiftUI

struct MainTabView: View {
    let user: UserInfo
    let onLogout: () -> Void
    @State private var selectedTab = 0
    
    // default initializer for previews
    init(user: UserInfo = UserInfo(name: "", groupName: ""),onLogout: @escaping () -> Void = {}) {
        self.user = user
        self.onLogout = onLogout
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home tab gets the user's values
            HomeView(name: user.name, groupName: user.groupName)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
            
            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .tag(1)
            
            ProfileView(onLogout: onLogout)
                .tabItem{
                    Label("Profile", systemImage:"person.crop.circle")}
                .tag(2)
                
        }
        .tint(.green) // tint for selected screen
    }
}



#Preview {
    MainTabView()
}
