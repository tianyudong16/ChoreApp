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
    
    @State private var showApprovalAlert = false
    
    // State to hold the chore that needs approval
    // In a real app, you would fetch this from Firebase
    // when the view appears.
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
                // Second column shows the first names of each group member
                Text("Profile Pic")
                    .frame(width: 50, height: 50)
                    .background(Color.gray)
                    .clipShape(Circle())
                Text("Name")
            }

            
            Spacer()
            
            // Chores Button
            NavigationLink(destination: ChoresView()) {
                Text("View Chores")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity) // Make it wide
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            // Add Chore Button
            Button("Add Chore") {
                // do stuff
            }
            .padding(.horizontal)
            Spacer()
            
        }
        .padding()
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        
        
        // Pending Approvals Alert
        .alert(
            "Approval Request", // The title
            isPresented: $showApprovalAlert,
            presenting: choreToApprove // pass in chore name
        ) { choreName in
            // Defining alert actions
            
            // "Approve" Button
            Button("Approve") {
                // Put your approval logic here
                print("Approved \(choreName)!")
                // e.g., FirebaseInterface.shared.approveTask(choreName)
                
                // After approving, clear the chore so the button hides
                withAnimation {
                    choreToApprove = nil
                }
            }
            
            // "Deny" Button
            Button("Deny", role: .destructive) {
                print("Denied \(choreName)!")
                // e.g., FirebaseInterface.shared.denyTask(choreName)
                
                // After denying, clear the chore so the button hides
                withAnimation {
                    choreToApprove = nil
                }
            }
            
            // "Cancel" Button
            Button("Cancel", role: .cancel) {
                // Alert just closes, chore is still pending
            }
            
        } message: { choreName in
            // The dynamic message for the alert
            Text("A group member has requested approval for: \"\(choreName)\". Do you approve?")
        }
        
        .onAppear {
            // In a real app, you would fetch pending chores here
            // e.g., FirebaseInterface.shared.fetchPendingChore { chore in
            //    self.choreToApprove = chore
            // }
        }
    }
}

#Preview {
    HomeView(name: "", groupName: "")
}
