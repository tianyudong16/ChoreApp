//
//  ChoreEquityView.swift
//  Chorely
//
//  Created by Brooke Tanner on 12/3/25.
//

import SwiftUI

struct ChoreEquityView: View {
    @ObservedObject var viewModel: ChoresViewModel
    let userName: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header using HeaderView
                HeaderView(
                    title: "Chore Equity",
                    subtitle: "See how chores are shared",
                    angle: 15,
                    background: .green
                )
                .padding(.bottom, -80)
                
                // House completion stats
                houseCompletionSection
                
                Divider()
                    .padding(.horizontal)
                
                // Individual member completion stats with progress bars
                memberProgressSection
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // House completion section
    private var houseCompletionSection: some View {
        VStack(spacing: 20) {
            Text("House Completion")
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            HStack(spacing: 24) {
                Spacer()
                
                VStack(spacing: 8) {
                    DonutProgressView(progress: houseCompletionRate, lineWidth: 14)
                        .frame(width: 110, height: 110)
                    
                    Text("Overall")
                        .font(.headline)
                    
                    Text(houseCompletionText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 8) {
                    DonutProgressView(progress: userCompletionRate, lineWidth: 14)
                        .frame(width: 110, height: 110)
                    
                    Text(userName)
                        .font(.headline)
                    
                    Text(userCompletionText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(.top, 12)
    }
    
    // Member progress section with bars
    private var memberProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Roommate Progress")
                    .font(.title2.bold())
                Spacer()
            }
            .padding(.horizontal)
            
            if viewModel.roommateStats.isEmpty {
                Text("No group members found")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.roommateStats) { stat in
                        MemberProgressRow(
                            stat: stat,
                            isCurrentUser: stat.name == userName
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }
    
    // Computes house completion
    private var houseCompletionRate: Double {
        let allChores = Array(viewModel.chores.values)
        let total = allChores.count
        guard total > 0 else { return 0 }
        let completed = allChores.filter { $0.completed }.count
        return Double(completed) / Double(total)
    }
    
    private var houseCompletionText: String {
        let allChores = Array(viewModel.chores.values)
        let total = allChores.count
        let completed = allChores.filter { $0.completed }.count
        return "\(completed) / \(total) completed"
    }
    
    // Computes chore completion just for the user
    private var userCompletionRate: Double {
        let allChores = Array(viewModel.chores.values)
        let assigned = allChores.filter { $0.assignedUsers.contains(userName) }
        let total = assigned.count
        guard total > 0 else { return 0 }
        let completed = assigned.filter { $0.completed }.count
        return Double(completed) / Double(total)
    }
    
    private var userCompletionText: String {
        let allChores = Array(viewModel.chores.values)
        let assigned = allChores.filter { $0.assignedUsers.contains(userName) }
        let total = assigned.count
        let completed = assigned.filter { $0.completed }.count
        return "\(completed) / \(total) completed"
    }
}

// Row showing individual member progress with colored bar
struct MemberProgressRow: View {
    let stat: RoommateStats
    let isCurrentUser: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // Color indicator and name
                HStack(spacing: 10) {
                    Circle()
                        .fill(stat.color)
                        .frame(width: 12, height: 12)
                    
                    Text(stat.name)
                        .font(.headline)
                        .foregroundColor(isCurrentUser ? .accentColor : .primary)
                    
                    if isCurrentUser {
                        Text("(You)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Completion percentage
                Text("\(Int(stat.completionRate * 100))%")
                    .font(.subheadline.bold())
                    .foregroundColor(completionColor)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(stat.color)
                        .frame(width: geometry.size.width * CGFloat(stat.completionRate), height: 8)
                }
            }
            .frame(height: 8)
            
            // Completion count
            HStack {
                Text("\(stat.completedCount)/\(stat.totalAssignedCount) chores completed")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if stat.totalAssignedCount == 0 {
                    Text("No assigned chores")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private var completionColor: Color {
        switch stat.completionRate {
        case 0.8...1.0: return .green
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }
}

// For the circle progress view
struct DonutProgressView: View {
    let progress: Double   // 0-1 because it's a percent
    let lineWidth: CGFloat
    
    var clampedProgress: Double {
        min(max(progress, 0), 1)
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.green, .blue, .green]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            Text("\(Int(clampedProgress * 100))%")
                .font(.headline)
        }
    }
}

#Preview {
    // Just for the preview
    let vm = ChoresViewModel()
    
    // Create sample data for preview
    vm.roommateStats = [
        RoommateStats(name: "You", completedCount: 8, totalAssignedCount: 10, color: .blue),
        RoommateStats(name: "Alex", completedCount: 6, totalAssignedCount: 8, color: .green),
        RoommateStats(name: "Taylor", completedCount: 5, totalAssignedCount: 7, color: .orange),
        RoommateStats(name: "Jordan", completedCount: 3, totalAssignedCount: 5, color: .purple),
        RoommateStats(name: "Casey", completedCount: 0, totalAssignedCount: 2, color: .red)
    ]
    
    return NavigationStack {
        ChoreEquityView(viewModel: vm, userName: "You")
    }
}
