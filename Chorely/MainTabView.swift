//
//  MainTabView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 10/30/25.
//

import SwiftUI

struct MainTabView: View {
    
    let user: UserInfo
    @State private var selectedTab = 0
    @State private var members: [GroupMember] = []
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            // HOME TAB
            HomeView(user: user, members: members)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // CHORES TAB
            ChoresView(user: user)
                .tabItem {
                    Label("Chores", systemImage: "checkmark.circle.fill")
                }
                .tag(1)
            
            // CALENDAR TAB
            CalendarView(user: user)
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(2)
            
            // PROFILE TAB
            ProfileView(user: user)
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(3)
        }
        .onAppear {
            startMemberListener()
        }
    }
    
    // MARK: - Listen to group members
    private func startMemberListener() {
        FirebaseInterface.shared.listenToGroupMembers(
            groupID: user.groupID
        ) { updatedMembers in
            DispatchQueue.main.async {
                self.members = updatedMembers
            }
        }
    }
}

#Preview {
    let previewUser = UserInfo(
        uid: "123",
        name: "Preview User",
        email: "preview@demo.com",
        groupID: "group1",
        photoURL: "",
        colorData: UIColor.systemPink.toData() ?? Data()
    )
    
    return MainTabView(user: previewUser)
}
