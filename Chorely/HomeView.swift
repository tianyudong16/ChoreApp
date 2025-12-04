//
//  HomeView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 10/30/25.
//

import SwiftUI
import FirebaseFirestore

// Model representing a member of the user's group
// Used for displaying group member avatars
struct GroupMember: Identifiable {
    let id: String    // Firebase document ID
    let name: String  // Display name
    let color: Color  // User's chosen color for their avatar
    
    // Converts a color name string to a SwiftUI Color
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

// Main home screen showing welcome message, group members, and action buttons
struct HomeView: View {
    var name: String      // Current user's name
    var groupName: String // Name of the user's group
    var userID: String    // Firebase user ID
    
    // ViewModel for calendar data (shared with DailyTasksView)
    @StateObject private var calendarViewModel = CalendarViewModel()
    
    @StateObject private var choresViewModel = ChoresViewModel()

    
    // State for UI elements
    @State private var showApprovalAlert = false      // Controls approval alert visibility
    @State private var selectedPendingChore: (id: String, chore: Chore)? = nil
    @State private var groupMembers: [GroupMember] = [] // List of group members
    @State private var isLoadingMembers = true        // Shows loading indicator
    @State private var groupKeyString: String? //keeps group key so chores can be deleted/edited
    
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
        
        // Approval request alert (for future feature)
        .alert("Approval Request", isPresented: $showApprovalAlert) {
            // APPROVE
            Button("Approve") {
                guard
                    let pending = selectedPendingChore,
                    let groupKey = groupKeyString
                else { return }

                var updated = pending.chore
                updated.proposal = false   // now approved
                
                // Generate a series ID for repeating chores
                let seriesId = updated.repetitionTime != "None" ? UUID().uuidString : ""
                updated.seriesId = seriesId

                editChore(documentId: pending.id, chore: updated, groupKey: groupKey) { success in
                    if success {
                        // Remove from local pending list
                        if let index = choresViewModel.pendingChores.firstIndex(where: { $0.id == pending.id }) {
                            choresViewModel.pendingChores.remove(at: index)
                        }
                        
                        // Generate future occurrences for repeating chores
                        if updated.repetitionTime != "None" && !updated.repetitionTime.isEmpty {
                            FirebaseInterface.shared.generateRepetitions(
                                for: updated,
                                groupKey: groupKey,
                                seriesId: seriesId
                            )
                        }
                    }
                }
            }

            // REJECT
            Button("Reject", role: .destructive) {
                guard
                    let pending = selectedPendingChore,
                    let groupKey = groupKeyString
                else { return }

                FirebaseInterface.shared.deleteChore(groupKey: groupKey, choreId: pending.id) { _ in
                        if let index = choresViewModel.pendingChores.firstIndex(where: { $0.id == pending.id }) {
                            choresViewModel.pendingChores.remove(at: index)
                        }
                    }
            }

            Button("Cancel", role: .cancel) { }

        } message: {
            if let chore = selectedPendingChore?.chore {
                    Text("A group member has requested approval for: \"\(chore.name)\". Do you approve?")
                } else {
                    Text("No chore selected.")
                }
        }
        .onAppear {
            // Load group members and calendar data when view appears
            fetchGroupMembers()
            calendarViewModel.loadData(userID: userID)
        }
    }
    
    // Welcome message and group name display
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
    
    // Section showing all group members with their avatars
    private var groupMembersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Group Members")
                .font(.headline)
                .foregroundColor(.secondary)
            
            // Show different content based on loading state
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
    
    // Loading indicator while fetching members
    private var loadingMembersView: some View {
        HStack {
            ProgressView()
                .padding(.trailing, 8)
            Text("Loading members...")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    // Shown when no group members found
    private var emptyMembersView: some View {
        Text("No members found")
            .foregroundColor(.secondary)
            .italic()
    }
    
    // Horizontal scrolling list of member avatars
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
    
    // Navigation buttons to Today's Chores and View Chores
    private var actionButtonsSection: some View {
        // Filter pending chores to only show ones NOT created by current user
        let approvableChores = choresViewModel.pendingChores.filter { $0.chore.createdBy != userID }
        
        return VStack(spacing: 12) {
            // Today's Chores button - opens DailyTasksView for today
            NavigationLink(destination: DailyTasksView(userID: userID, currentUserName: name, selectedDate: Date(), viewModel: calendarViewModel)) {
                ActionButtonLabel(title: "Today's Chores", color: .green)
            }
            
            // View Chores button - opens full ChoresView
            NavigationLink(destination: ChoresView(userID: userID)) {
                ActionButtonLabel(title: "View Chores", color: .blue)
            }
            // Only show pending approvals button if there are chores to approve
            // (excludes chores created by current user)
            if !approvableChores.isEmpty, groupKeyString != nil {
                Button {
                    selectedPendingChore = approvableChores.first
                    showApprovalAlert = true
                } label: {
                    ActionButtonLabel(
                        title: "Pending Approvals (\(approvableChores.count))",
                        color: .orange
                    )
                }
            }
            //Button that takes user to chore equity page
            NavigationLink(
                destination: ChoreEquityView(
                    viewModel: choresViewModel,
                    userName: name
                )
            ) {
                ActionButtonLabel(title: "Chore Equity", color: .purple)
            }
        }
        .padding(.horizontal)
    }
    
    // Fetches all members in the user's group from Firebase
    private func fetchGroupMembers() {
        isLoadingMembers = true
        
        Task {
            do {
                // Get current user's data to find their groupKey
                let userData = try await FirebaseInterface.shared.getUserData(uid: userID)
                let keys = FirebaseInterface.shared.extractGroupKey(from: userData)
                
                guard let groupKeyInt = keys.int, let groupKeyStr = keys.string
                else {
                    print("Could not find groupKey for current user")
                    await MainActor.run { isLoadingMembers = false }
                    return
                }
                
                await MainActor.run {
                    self.groupKeyString = groupKeyStr
                    choresViewModel.startListening(groupKey: groupKeyStr)
                }
                
                // Fetch all users with the same groupKey
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
                        
                        // Convert Firestore documents to GroupMember objects
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
    
    // Converts Firestore documents into GroupMember objects
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

// Circular avatar showing a group member's initial and color
struct MemberAvatarView: View {
    let member: GroupMember
    
    var body: some View {
        VStack(spacing: 8) {
            // Colored circle with initial
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

// Reusable button label for navigation links
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


//dummy data so preview works
#Preview {
    NavigationStack {
        HomeView(
            name: "Test User",
            groupName: "Test Group",
            userID: "preview-user-not-real"
        )
        .environmentObject(ChoresViewModel()) // optional but safe
    }
}
