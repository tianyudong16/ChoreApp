//
//  ChoreEquityView.swift
//  Chorely
//
//  Created by Brooke Tanner on 12/3/25.
//

import SwiftUI

// model for score display
struct MemberScore: Identifiable {
    let id = UUID()
    let name: String
    let score: Int
    let color: Color
    let numChores: Int
}

struct ChoreEquityView: View {

    @ObservedObject var viewModel: ChoresViewModel
    let userName: String

    @State private var scores: [MemberScore] = []
    @State private var loadingScores = true

    var body: some View {
        VStack(spacing: 0) {
            //header
            VStack(spacing: 8) {
                Text("Chore Equity")
                    .font(.largeTitle.bold())
                    .foregroundColor(.green)
                Text("See fairness for your house")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            
            ScrollView {
                VStack(spacing: 30) {
                    //progress circles section
                    donutsSection
                    Divider()
                    //roommate scores section (calculated using firebase method)
                    scoreListSection
                }
                .padding()
            }
        }
        .onAppear {
            Task { await loadFirebaseScores() }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    
    //load scores from firebase
    func loadFirebaseScores() async {
        loadingScores = true

        guard let groupKey = viewModel.currentGroupKey else {
            print("No group key")
            loadingScores = false
            return
        }

        //wait for group members to be loaded by the view model
        var attempts = 0
        while viewModel.groupMembers.isEmpty && attempts < 50 {
            try? await Task.sleep(nanoseconds: 100_000_000)
            attempts += 1
        }
        
        if viewModel.groupMembers.isEmpty {
            print("No group members loaded after waiting")
            loadingScores = false
            return
        }
        
        print("Found \(viewModel.groupMembers.count) group members")

        var temp: [MemberScore] = []

        for member in viewModel.groupMembers {
            do {
                //calculates score
                let score = try await FirebaseInterface.shared.calculateScoreForUser(
                    uid: member.id,
                    groupKey: groupKey,
                )
                
                let numChores = try await FirebaseInterface.shared.getNumLogChores(
                    uid: member.id,
                    groupKey: groupKey,
                )

                temp.append(
                    MemberScore(
                        name: member.name,
                        score: score,
                        color: member.color,
                        numChores: numChores,
                    )
                )
                
                print("Loaded score for \(member.name): \(score) pts")

            } catch {
                print("Error loading score for \(member.name): \(error)")
            }
        }

        //sorts users from highest to lowest based on scores for ranking
        scores = temp.sorted(by: { $0.score > $1.score })
        loadingScores = false
        
        print("Final scores: \(scores.map { "\($0.name): \($0.score)" }.joined(separator: ", "))")
    }

    //donuts section (progress circles)
    private var donutsSection: some View {
        VStack(spacing: 16) {
            Text("Chore Completion")
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    //users chores to do that week
                    donutCard(title: "Your Week", progress: userWeeklyProgress())
                    //users chores to do that month
                    donutCard(title: "Your Month", progress: userMonthlyProgress())
                }
                
                HStack(spacing: 16) {
                    //all chores for the house that week
                    donutCard(title: "House Week", progress: houseWeeklyProgress())
                    //all chores for the house that month
                    donutCard(title: "House Month", progress: houseMonthlyProgress())
                }
            }
        }
    }

    //layout for donut
    private func donutCard(title: String, progress: Double) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)

                //progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 80, height: 80)

                //percentage text
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 16, weight: .bold))
            }

            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    //ranking/score section
    private var scoreListSection: some View {
        VStack(spacing: 16) {
            Text("Roommate Rankings")
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            if loadingScores {
                HStack {
                    ProgressView()
                    Text("Loading scores...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if scores.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("No scores available")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(scoresWithRanks.enumerated()), id: \.element.member.id) { index, item in
                        scoreCard(item.member, rank: item.rank, isTied: item.isTied)
                    }
                }
            }
        }
    }
    
    // Calculate ranks with tie handling
    private var scoresWithRanks: [(member: MemberScore, rank: Int, isTied: Bool)] {
        var result: [(member: MemberScore, rank: Int, isTied: Bool)] = []
        var currentRank = 1
        
        for (index, score) in scores.enumerated() {
            //check if tied with previous
            let isTiedWithPrevious = index > 0 && scores[index - 1].score == score.score
            //check if tied with next
            let isTiedWithNext = index < scores.count - 1 && scores[index + 1].score == score.score
            let isTied = isTiedWithPrevious || isTiedWithNext
            
            //use same rank as previous if tied
            if isTiedWithPrevious {
                result.append((member: score, rank: result[index - 1].rank, isTied: isTied))
            } else {
                result.append((member: score, rank: currentRank, isTied: isTied))
            }
            
            //only increment rank if not tied with next
            if !isTiedWithNext {
                currentRank = index + 2
            }
        }
        
        return result
    }

    private func scoreCard(_ s: MemberScore, rank: Int, isTied: Bool) -> some View {
        HStack(spacing: 12) {
            //rank badge
            ZStack {
                Circle()
                    .fill(rank == 1 ? Color.yellow.opacity(0.3) : Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                if isTied {
                    Text("T\(rank)")
                        .font(.subheadline.bold())
                        .foregroundColor(rank == 1 ? .orange : .secondary)
                } else {
                    Text("#\(rank)")
                        .font(.headline.bold())
                        .foregroundColor(rank == 1 ? .orange : .secondary)
                }
            }

            //user avatar
            Circle()
                .fill(s.color)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(s.name.prefix(1).uppercased())
                        .foregroundColor(.white)
                        .font(.headline.bold())
                )

            //name and score
            VStack(alignment: .leading, spacing: 2) {
                Text(s.name)
                    .font(.headline)
                Text("\(s.score) points")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
            
            //trophy for housemember with most chores completed
            if rank == 1 {
                Image(systemName: isTied ? "trophy" : "trophy.fill")
                    .foregroundColor(.yellow)
                    .font(.title2)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    
    //progress calculations
    private func userWeeklyProgress() -> Double {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        
        let userChores = viewModel.approvedChores.filter { item in
            guard let choreDate = dateFromString(item.chore.date) else { return false }
            return item.chore.assignedUsers.contains(userName) && choreDate >= weekAgo && choreDate <= now
        }
        
        guard !userChores.isEmpty else { return 0 }
        let completed = userChores.filter { $0.chore.completed }.count
        return Double(completed) / Double(userChores.count)
    }
    
    private func userMonthlyProgress() -> Double {
        let calendar = Calendar.current
        let now = Date()
        let monthAgo = calendar.date(byAdding: .day, value: -30, to: now)!
        
        let userChores = viewModel.approvedChores.filter { item in
            guard let choreDate = dateFromString(item.chore.date) else { return false }
            return item.chore.assignedUsers.contains(userName) && choreDate >= monthAgo && choreDate <= now
        }
        
        guard !userChores.isEmpty else { return 0 }
        let completed = userChores.filter { $0.chore.completed }.count
        return Double(completed) / Double(userChores.count)
    }
    
    private func houseWeeklyProgress() -> Double {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        
        let houseChores = viewModel.approvedChores.filter { item in
            guard let choreDate = dateFromString(item.chore.date) else { return false }
            return choreDate >= weekAgo && choreDate <= now
        }
        
        guard !houseChores.isEmpty else { return 0 }
        let completed = houseChores.filter { $0.chore.completed }.count
        return Double(completed) / Double(houseChores.count)
    }
    
    private func houseMonthlyProgress() -> Double {
        let calendar = Calendar.current
        let now = Date()
        let monthAgo = calendar.date(byAdding: .day, value: -30, to: now)!
        
        let houseChores = viewModel.approvedChores.filter { item in
            guard let choreDate = dateFromString(item.chore.date) else { return false }
            return choreDate >= monthAgo && choreDate <= now
        }
        
        guard !houseChores.isEmpty else { return 0 }
        let completed = houseChores.filter { $0.chore.completed }.count
        return Double(completed) / Double(houseChores.count)
    }
    
    private func dateFromString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
}
