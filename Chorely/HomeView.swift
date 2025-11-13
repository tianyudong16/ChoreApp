//
//  HomeView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 10/30/25.
//

import SwiftUI

struct HomeView: View {
    
    let user: UserInfo
    let members: [GroupMember]
    
    @State private var todaysChores: [ChoreItem] = []
    @State private var pendingApprovals: [ChoreItem] = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // Header
                Text("House Group Dashboard")
                    .font(.title2.bold())
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // Displaying group members
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.blue)
                                Text("Members")
                                    .font(.headline)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            // Members list with their respective colored backgrounds
                            VStack(spacing: 8) {
                                ForEach(members) { member in
                                    memberCard(member)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // View chores button
                        NavigationLink {
                            ChoresView(user: user)
                        } label: {
                            HStack {
                                Image(systemName: "list.bullet.clipboard.fill")
                                    .font(.title2)
                                Text("View Chores")
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Today's chores count
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "checklist")
                                    .foregroundColor(.orange)
                                Text("Today's Chores")
                                    .font(.headline)
                                Spacer()
                                Text("\(todaysChores.count)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange)
                                    .clipShape(Capsule())
                            }
                            .padding(.horizontal)
                            
                            if !todaysChores.isEmpty {
                                VStack(spacing: 8) {
                                    ForEach(todaysChores.prefix(3)) { chore in
                                        todayChoreRow(chore: chore)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Shows pending approvals
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "clock.badge.exclamationmark")
                                    .foregroundColor(.red)
                                Text("Pending Approvals")
                                    .font(.headline)
                                Spacer()
                                Text("\(pendingApprovals.count)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red)
                                    .clipShape(Capsule())
                            }
                            .padding(.horizontal)
                            
                            if !pendingApprovals.isEmpty {
                                VStack(spacing: 8) {
                                    ForEach(pendingApprovals.prefix(3)) { approval in
                                        pendingApprovalRow(approval: approval)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        Spacer(minLength: 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadTodaysChores()
            }
        }
    }
    
    // Loading daily chores
    private func loadTodaysChores() {
        FirebaseInterface.shared.fetchChores(groupID: user.groupID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let chores):
                    // Filter for today's date or daily chores
                    let calendar = Calendar.current
                    let today = Date()
                    
                    self.todaysChores = chores.filter { chore in
                        if chore.isPending { return false } // Exclude pending
                        if let dueDate = chore.dueDate {
                            return calendar.isDate(dueDate, inSameDayAs: today)
                        }
                        return chore.repetition == "daily"
                    }
                    
                    // Pending approvals are chores where isPending = true
                    self.pendingApprovals = chores.filter { $0.isPending }
                    
                case .failure(let error):
                    print("Error loading chores: \(error)")
                }
            }
        }
    }
    
    // Approving chores
    private func approveChore(_ chore: ChoreItem) {
        FirebaseInterface.shared.approveChore(choreID: chore.id.uuidString, groupID: user.groupID)
        
        // Remove from pending list immediately for UI feedback
        pendingApprovals.removeAll { $0.id == chore.id }
        
        // Reload all chores after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            loadTodaysChores()
        }
    }
    
    // Denying chores
    private func denyChore(_ chore: ChoreItem) {
        FirebaseInterface.shared.denyChore(choreID: chore.id.uuidString, groupID: user.groupID)
        
        // Remove from pending list immediately for UI feedback
        pendingApprovals.removeAll { $0.id == chore.id }
        
        // Reload all chores after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            loadTodaysChores()
        }
    }
    
    // Shows profile picture of each group member
    @ViewBuilder
    func memberCard(_ member: GroupMember) -> some View {
        HStack(spacing: 12) {
            // Photo or colored circle
            if !member.photoURL.isEmpty {
                AsyncImage(url: URL(string: member.photoURL)) { image in
                    image.resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.fromData(member.colorData))
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.fromData(member.colorData))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(member.name.prefix(1)))
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    )
            }
            
            // Name
            Text(member.name)
                .font(.body.weight(.medium))
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.fromData(member.colorData).opacity(0.15))
        )
    }
    
    // Pending approval row
    @ViewBuilder
    func pendingApprovalRow(approval: ChoreItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(approval.name)
                        .font(.body.weight(.medium))
                    Text("Proposed by \(approval.proposedBy)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    // Show chore details
                    HStack(spacing: 8) {
                        Label("\(approval.priorityName)", systemImage: "exclamationmark.circle")
                            .font(.caption2)
                        Label("\(approval.estimatedTime)min", systemImage: "clock")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button(action: { approveChore(approval) }) {
                    Text("Approve")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .cornerRadius(8)
                }
                
                Button(action: { denyChore(approval) }) {
                    Text("Deny")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
    
    // Daily chores
    @ViewBuilder
    func todayChoreRow(chore: ChoreItem) -> some View {
        HStack {
            Image(systemName: chore.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(chore.isCompleted ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(chore.name)
                    .font(.body.weight(.medium))
                if !chore.assignedTo.isEmpty {
                    Text(chore.assignedTo)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    HomeView(
        user: UserInfo(
            uid: "123",
            name: "Preview User",
            email: "preview@email.com",
            groupID: "group1",
            photoURL: "",
            colorData: UIColor.systemPink.toData() ?? Data()
        ),
        members: [
            GroupMember(
                uid: "1",
                name: "Emily",
                photoURL: "",
                colorData: UIColor.systemPink.toData() ?? Data()
            ),
            GroupMember(
                uid: "2",
                name: "Alex",
                photoURL: "",
                colorData: UIColor.systemBlue.toData() ?? Data()
            ),
            GroupMember(
                uid: "3",
                name: "Jordan",
                photoURL: "",
                colorData: UIColor.systemGreen.toData() ?? Data()
            )
        ]
    )
}
