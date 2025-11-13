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
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // MARK: - HEADER with Dashboard title
                Text("House Group Dashboard")
                    .font(.title2.bold())
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // MARK: - MEMBERS SECTION
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.blue)
                                Text("Members")
                                    .font(.headline)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            // Members list with colored backgrounds
                            VStack(spacing: 8) {
                                ForEach(members) { member in
                                    memberCard(member)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // MARK: - VIEW CHORES BUTTON
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
                        
                        // MARK: - TODAY'S CHORES
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "checklist")
                                    .foregroundColor(.orange)
                                Text("Today's Chores")
                                    .font(.headline)
                                Spacer()
                                Text("3")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange)
                                    .clipShape(Capsule())
                            }
                            .padding(.horizontal)
                            
                            // Sample chores
                            VStack(spacing: 8) {
                                todayChoreRow(name: "Taking Out Trash", isCompleted: false, assignee: "Emily")
                            }
                            .padding(.horizontal)
                        }
                        
                        // MARK: - PENDING APPROVALS
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "clock.badge.exclamationmark")
                                    .foregroundColor(.red)
                                Text("Pending Approvals")
                                    .font(.headline)
                                Spacer()
                                Text("1")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red)
                                    .clipShape(Capsule())
                            }
                            .padding(.horizontal)
                            
                            // Sample pending approval
                            pendingApprovalRow(
                                choreName: "Clean Bathroom",
                                requester: "Housemate 2",
                                onApprove: {
                                    // Approve action
                                },
                                onDeny: {
                                    // Deny action
                                }
                            )
                            .padding(.horizontal)
                        }
                        
                        // MARK: - ADD CHORE BUTTON
                        NavigationLink {
                            ChoresView(user: user)
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text("Add Chore")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - MEMBER CARD
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
    
    // MARK: - PENDING APPROVAL ROW
    @ViewBuilder
    func pendingApprovalRow(
        choreName: String,
        requester: String,
        onApprove: @escaping () -> Void,
        onDeny: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(choreName)
                        .font(.body.weight(.medium))
                    Text("Requested by \(requester)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button(action: onApprove) {
                    Text("Approve")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .cornerRadius(8)
                }
                
                Button(action: onDeny) {
                    Text("Deny")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
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
    
    // MARK: - TODAY CHORE ROW
    @ViewBuilder
    func todayChoreRow(name: String, isCompleted: Bool, assignee: String) -> some View {
        HStack {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(isCompleted ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.body.weight(.medium))
                Text(assignee)
                    .font(.caption)
                    .foregroundColor(.gray)
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

// MARK: - DAILY TASKS VIEW (Replaces ChoreLogView)
struct DailyTasksView: View {
    let user: UserInfo
    
    @State private var tasks: [TaskItem] = [
        TaskItem(name: "Taking Out Trash", isCompleted: false, assignee: "Emily"),
        TaskItem(name: "Dishes", isCompleted: true, assignee: "Housemate 2")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Daily Tasks")
                .font(.title2.bold())
                .padding(.top, 20)
                .padding(.bottom, 10)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(tasks) { task in
                        taskRow(task)
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    func taskRow(_ task: TaskItem) -> some View {
        HStack {
            Button {
                // Toggle completion
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.body.weight(.medium))
                    .strikethrough(task.isCompleted)
                Text(task.assignee)
                    .font(.caption)
                    .foregroundColor(.gray)
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

struct TaskItem: Identifiable {
    let id = UUID()
    var name: String
    var isCompleted: Bool
    var assignee: String
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
                name: "Housemate 2",
                photoURL: "",
                colorData: UIColor.systemBlue.toData() ?? Data()
            ),
            GroupMember(
                uid: "3",
                name: "Housemate 3",
                photoURL: "",
                colorData: UIColor.systemGreen.toData() ?? Data()
            )
        ]
    )
}
