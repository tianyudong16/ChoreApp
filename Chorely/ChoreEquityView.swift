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
    
    //computes house completion
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
    //computes chore completion just for the user
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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                //header using HeaderView
                HeaderView(
                    title: "Chore Equity",
                    subtitle: "See how chores are shared",
                    angle: 15,
                    background: .green
                )
                .padding(.bottom, -80)
                
                //circle completion visualisation
                VStack(spacing: 20) {
                    Text("Completion Overview")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    HStack(spacing: 24) {
                        Spacer()
                        
                        VStack(spacing: 8) {
                            DonutProgressView(progress: houseCompletionRate, lineWidth: 14)
                                .frame(width: 110, height: 110)
                            
                            Text("House")
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
                
                Divider()
                    .padding(.horizontal)
                
                // Roommate “leaderboard”
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Roommate Standings")
                            .font(.title2.bold())
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    if viewModel.roommateStats.isEmpty {
                        Text("")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        VStack(spacing: 10) {
                            ForEach(viewModel.roommateStats) { stat in
                                HStack {
                                    if let index = viewModel.roommateStats.firstIndex(where: { $0.id == stat.id }) {
                                        Text("#\(index + 1)")
                                            .font(.subheadline.bold())
                                            .frame(width: 30, alignment: .leading)
                                    } else {
                                        Text("•")
                                            .frame(width: 30, alignment: .leading)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(stat.name)
                                            .font(.headline)
                                        
                                        Text("\(stat.completedCount)/\(stat.totalAssignedCount) completed")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(Int(stat.completionRate * 100))%")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.green)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

//for the circle progress view
struct DonutProgressView: View {
    let progress: Double   //0-1 because its a percent
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
    //just for the preview
    let vm = ChoresViewModel()
    vm.chores = [:]  // empty for preview
    return NavigationStack {
        ChoreEquityView(viewModel: vm, userName: "You")
    }
}
