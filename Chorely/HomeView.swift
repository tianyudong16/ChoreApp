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
    @StateObject private var calendarViewModel = CalendarViewModel()
    
    @State private var showApprovalAlert = false
    @State private var choreToApprove: String? = "Wash the dishes" // Sample chore
    @State private var groupMembers: [GroupMember] = []
    @State private var isLoadingMembers = true
    
    var body: some View {
        VStack {
            welcomeHeader
            groupMembersSection
            Spacer()
            actionButtonsSection
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
            fetchGroupMembers()
            calendarViewModel.loadData(userID: userID)
        }
    }
    
    private var welcomeHeader: some View {
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
        }
    }
    
    private var groupMembersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Group Members")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if isLoadingMembers {
                loadingMembersView
            } else if groupMembers.isEmpty {
                emptyMembersView
            } else {
                membersScrollView
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }
    
    private var loadingMembersView: some View {
        HStack {
            ProgressView()
                .padding(.trailing, 8)
            Text("Loading members...")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private var emptyMembersView: some View {
        Text("No members found")
            .foregroundColor(.secondary)
            .italic()
    }
    
    private var membersScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(groupMembers) { member in
                    MemberAvatarView(member: member)
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            NavigationLink(destination: DailyTasksView(userID: userID, selectedDate: Date(), viewModel: calendarViewModel)) {
                ActionButtonLabel(title: "Today's Chores", color: .green)
            }
            
            NavigationLink(destination: ChoresView(userID: userID)) {
                ActionButtonLabel(title: "View Chores", color: .blue)
            }
        }
        .padding(.horizontal)
    }
    
    private func fetchGroupMembers() {
        isLoadingMembers = true
        
        Task {
            do {
                let userData = try await FirebaseInterface.shared.getUserData(uid: userID)
                let keys = FirebaseInterface.shared.extractGroupKey(from: userData)
                
                guard let groupKeyInt = keys.int else {
                    print("Could not find groupKey for current user")
                    await MainActor.run { isLoadingMembers = false }
                    return
                }
                
                FirebaseInterface.shared.fetchGroupMembers(groupKey: groupKeyInt) { documents, error in
                    DispatchQueue.main.async {
                        isLoadingMembers = false
                        
                        if let error = error {
                            print("Error fetching group members: \(error)")
                            return
                        }
                        
                        guard let documents = documents else {
                            print("No documents found")
                            return
                        }
                        
                        groupMembers = readMemberDocuments(documents)
                        print("Loaded \(groupMembers.count) group members")
                    }
                }
            } catch {
                await MainActor.run {
                    print("Error fetching current user: \(error)")
                    isLoadingMembers = false
                }
            }
        }
    }
    
    private func readMemberDocuments(_ documents: [QueryDocumentSnapshot]) -> [GroupMember] {
        return documents.compactMap { doc -> GroupMember? in
            let data = doc.data()
            guard let name = data["Name"] as? String else { return nil }
            let colorString = data["color"] as? String ?? "Green"
            
            return GroupMember(
                id: doc.documentID,
                name: name,
                color: GroupMember.colorFromString(colorString)
            )
        }
    }
}

struct MemberAvatarView: View {
    let member: GroupMember
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(member.color)
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(member.name.prefix(1)).uppercased())
                        .font(.title2.bold())
                        .foregroundColor(.white)
                )
                .shadow(color: member.color.opacity(0.4), radius: 4, y: 2)
            
            Text(member.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .frame(maxWidth: 70)
        }
    }
}

struct ActionButtonLabel: View {
    let title: String
    let color: Color
    
    var body: some View {
        Text(title)
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(10)
    }
}

#Preview {
    NavigationStack {
        HomeView(name: "Test User", groupName: "Test Group", userID: "")
    }
}
