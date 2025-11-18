//
//  MainTabView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 10/30/25.
//

import SwiftUI

struct MainTabView: View {
    let user: UserInfo
    let onLogout: () -> Void
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
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
        .tint(.green)
    }
}

#Preview {
    MainTabView(user: UserInfo(uid: "test", name: "Test User", groupName: "Test Group", email: "test@test.com"), onLogout: {})
}
