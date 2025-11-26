//
//  HomeView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 10/30/25.
//

import SwiftUI

// Home Screen
struct HomeView: View {
    
    var name: String
    var groupName: String
    var userID: String
    
    @State private var showApprovalAlert = false
    @State private var choreToApprove: String? = "Wash the dishes" // Sample chore
    
    var body: some View {
        VStack {
            Text("Welcome \(name)!")
                .font(.title.bold())
            
            Text("Group: \(groupName)")
                .font(.title)
                .foregroundColor(.secondary)
                .padding(.bottom, 30)
            
            Text("House Group Dashboard")
                .fontWeight(.heavy)
                .font(.system(size: 30))
            
            HStack {
                Text("Profile Pic")
                    .frame(width: 50, height: 50)
                    .background(Color.gray)
                    .clipShape(Circle())
                Text("Name")
            }

            Spacer()
            
            NavigationLink(destination: DailyTasksView()) {
                Text("Today's Chores")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            NavigationLink(destination: ChoresView(userID: userID)) {
                Text("View Chores")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Spacer()
            
        }
        .padding()
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            "Approval Request",
            isPresented: $showApprovalAlert,
            presenting: choreToApprove
        ) { choreName in
            Button("Approve") {
                print("Approved \(choreName)!")
                withAnimation {
                    choreToApprove = nil
                }
            }
            Button("Deny", role: .destructive) {
                print("Denied \(choreName)!")
                withAnimation {
                    choreToApprove = nil
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { choreName in
            Text("A group member has requested approval for: \"\(choreName)\". Do you approve?")
        }
        .onAppear {
            // Fetch pending chores here
        }
    }
}

#Preview {
    HomeView(name: "Test User", groupName: "Test Group", userID: "")
}
