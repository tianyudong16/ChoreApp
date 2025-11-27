//
//  HomeView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 10/30/25.
//

import SwiftUI
import FirebaseFirestore

// Model for group member
struct GroupMember: Identifiable {
    let id: String
    let name: String
    let color: Color
    
    // Convert string color name to SwiftUI Color
    static func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "cyan": return .cyan
        case "mint": return .mint
        case "teal": return .teal
        case "indigo": return .indigo
        default: return .green
        }
    }
}

// Home Screen
struct HomeView: View {
    
    var name: String
    var groupName: String
    var userID: String
    
    @State private var showApprovalAlert = false
    @State private var choreToApprove: String? = "Wash the dishes" // Sample chore
    @State private var groupMembers: [GroupMember] = []
    @State private var isLoadingMembers = true
    
    var body: some View {
        VStack {
            Text("Welcome \(name)!")
                .font(.title.bold())
            
            Text("Group: \(groupName)")
                .font(.title)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
            
            Text("House Group Dashboard")
                .fontWeight(.heavy)
                .font(.system(size: 26))
                .padding(.bottom, 10)
            
            // Group Members Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Group Members")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                if isLoadingMembers {
                    HStack {
                        ProgressView()
                            .padding(.trailing, 8)
                        Text("Loading members...")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                } else if groupMembers.isEmpty {
                    Text("No members found")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(groupMembers) { member in
                                VStack(spacing: 8) {
                                    // Profile circle with member's color
                                    Circle()
                                        .fill(member.color)
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Text(String(member.name.prefix(1)).uppercased())
                                                .font(.title2.bold())
                                                .foregroundColor(.white)
                                        )
                                        .shadow(color: member.color.opacity(0.4), radius: 4, y: 2)
                                    
                                    // Member name
                                    Text(member.name)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                        .frame(maxWidth: 70)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            .padding(.horizontal)

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
            fetchGroupMembers() // calls function to get group members
        }
    }
    
    // Fetch all members with the same groupKey
    private func fetchGroupMembers() {
        isLoadingMembers = true
        
        // First get the current user's groupKey
        FirebaseInterface.shared.firestore
            .collection("Users")
            .document(userID)
            .getDocument { snapshot, error in
                if let error = error {
                    print("Error fetching current user: \(error)")
                    isLoadingMembers = false
                    return
                }
                
                guard let data = snapshot?.data(),
                      let groupKey = data["groupKey"] as? Int else {
                    print("Could not find groupKey for current user")
                    isLoadingMembers = false
                    return
                }
                
                // Now fetch all users with the same groupKey
                FirebaseInterface.shared.firestore
                    .collection("Users")
                    .whereField("groupKey", isEqualTo: groupKey)
                    .getDocuments { querySnapshot, error in
                        DispatchQueue.main.async {
                            isLoadingMembers = false
                            
                            if let error = error {
                                print("Error fetching group members: \(error)")
                                return
                            }
                            
                            guard let documents = querySnapshot?.documents else {
                                print("No documents found")
                                return
                            }
                            // compact map used to take every item in each document except for nil values
                            // doc -> GroupMember means from doc, return GroupMember
                            groupMembers = documents.compactMap { doc -> GroupMember? in
                                let data = doc.data() // gets dictionary of data from Firebase document
                                guard let name = data["Name"] as? String else { return nil }
                                let colorString = data["color"] as? String ?? "Green"
                                
                                return GroupMember(
                                    id: doc.documentID,
                                    name: name,
                                    color: GroupMember.colorFromString(colorString)
                                )
                            }
                            
                            print("Loaded \(groupMembers.count) group members")
                        }
                    }
            }
    }
}

#Preview {
    NavigationStack {
        HomeView(name: "Test User", groupName: "Test Group", userID: "")
    }
}
