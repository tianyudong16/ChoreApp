//
//  CalendarView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 10/30/25.
//

import SwiftUI

struct CalendarView: View {
    
    let user: UserInfo
    
    @State private var selectedDate: Date = Date()
    @State private var currentMonthOffset = 0
    @State private var viewMode: CalendarViewMode = .group
    @State private var members: [GroupMember] = []
    @State private var chores: [ChoreItem] = []
    
    enum CalendarViewMode {
        case group, roommate, personal
    }
    
    // Calculate completion count for each member
    private func completionCount(for member: GroupMember) -> Int {
        return chores.filter { $0.isCompleted && $0.assignedTo == member.name }.count
    }
    
    // Calculate total assigned chores for each member
    private func assignedCount(for member: GroupMember) -> Int {
        return chores.filter { $0.assignedTo == member.name && !$0.isPending }.count
    }
    
    // Calculate completion percentage
    private func completionPercentage(for member: GroupMember) -> Double {
        let assigned = assignedCount(for: member)
        if assigned == 0 { return 0.0 }
        let completed = completionCount(for: member)
        return Double(completed) / Double(assigned)
    }
    
    // Check if member completed all chores
    private func isFullyComplete(for member: GroupMember) -> Bool {
        let assigned = assignedCount(for: member)
        if assigned == 0 { return false }
        return completionCount(for: member) == assigned
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // MARK: - CALENDAR TITLE
                Text("Calendar")
                    .font(.title2.bold())
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                
                // MARK: - VIEW MODE PICKER
                HStack(spacing: 20) {
                    viewModeButton(mode: .group, title: "Group", icon: "person.3.fill")
                    viewModeButton(mode: .roommate, title: "Roommate", icon: "person.2.fill")
                    viewModeButton(mode: .personal, title: "Personal", icon: "person")
                }
                .padding(.horizontal)
                .padding(.bottom, 15)
                
                ScrollView {
                    VStack(spacing: 0) {
                        // MARK: - MONTH NAVIGATION
                        HStack {
                            Button(action: { currentMonthOffset -= 1 }) {
                                Image(systemName: "chevron.left")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                            }
                            
                            Spacer()
                            
                            Text(monthYearString(for: getCurrentMonth()))
                                .font(.title3.bold())
                            
                            Spacer()
                            
                            Button(action: { currentMonthOffset += 1 }) {
                                Image(systemName: "chevron.right")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                        
                        // MARK: - WEEKDAY LABELS
                        HStack(spacing: 0) {
                            ForEach(["S","M","T","W","T","F","S"], id: \.self) { day in
                                Text(day)
                                    .font(.caption.bold())
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal)
                        
                        // MARK: - CALENDAR GRID
                        let days = extractDates(for: getCurrentMonth())
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                            
                            ForEach(days) { dayValue in
                                
                                if dayValue.day == -1 {
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(height: 50)
                                } else {
                                    dayCell(dayValue)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        Divider()
                            .padding(.vertical, 15)
                        
                        // MARK: - WEEKLY CHORE STATS SECTION
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Weekly Chore Stats")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            if members.isEmpty {
                                Text("Loading members...")
                                    .foregroundColor(.gray)
                                    .padding()
                            } else {
                                VStack(spacing: 10) {
                                    weeklyStatsCard()
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadGroupMembers()
                loadChores()
            }
        }
    }
    
    // MARK: - LOAD GROUP MEMBERS
    private func loadGroupMembers() {
        FirebaseInterface.shared.listenToGroupMembers(groupID: user.groupID) { updatedMembers in
            DispatchQueue.main.async {
                self.members = updatedMembers
            }
        }
    }
    
    // MARK: - LOAD CHORES
    private func loadChores() {
        FirebaseInterface.shared.listenToChores(groupID: user.groupID) { updatedChores in
            DispatchQueue.main.async {
                self.chores = updatedChores
            }
        }
    }
    
    // MARK: - VIEW MODE BUTTON
    @ViewBuilder
    func viewModeButton(mode: CalendarViewMode, title: String, icon: String) -> some View {
        Button {
            viewMode = mode
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(viewMode == mode ? .blue : .gray)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(viewMode == mode ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
            )
        }
    }
    
    // MARK: - DAY CELL
    @ViewBuilder
    func dayCell(_ dayValue: DayValue) -> some View {
        
        NavigationLink(destination: ChoresView(user: user, selectedDate: dayValue.date)) {
            
            Text("\(dayValue.day)")
                .font(.callout)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    Circle()
                        .fill(
                            isSameDay(dayValue.date, Date()) ? Color.red : // Today is Red
                            isSameDay(dayValue.date, selectedDate) ? Color.blue.opacity(0.8) : // Selected is Blue
                            Color.blue.opacity(0.2) // All other dates have light blue background
                        )
                )
                .foregroundColor(
                    isSameDay(dayValue.date, Date()) || isSameDay(dayValue.date, selectedDate) ? .white : .primary
                )
        }
        .onTapGesture {
            selectedDate = dayValue.date
        }
    }
    
    // MARK: - WEEKLY STATS CARD
    @ViewBuilder
    func weeklyStatsCard() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Completion Level")
                .font(.subheadline.bold())
            
            VStack(spacing: 12) {
                ForEach(members) { member in
                    let completions = completionCount(for: member)
                    let assigned = assignedCount(for: member)
                    let percentage = completionPercentage(for: member)
                    let isComplete = isFullyComplete(for: member)
                    
                    HStack(spacing: 12) {
                        // User indicator circle
                        Circle()
                            .fill(Color.fromData(member.colorData))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Text(String(member.name.prefix(1)))
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                            )
                        
                        // Name
                        Text(member.name)
                            .font(.body)
                            .frame(width: 70, alignment: .leading)
                        
                        // Progress bar (percentage-based)
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                
                                // Progress (percentage of assigned chores)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(isComplete ? Color.green : Color.fromData(member.colorData))
                                    .frame(width: geometry.size.width * percentage)
                            }
                        }
                        .frame(height: 8)
                        
                        // Completion fraction and checkmark
                        HStack(spacing: 4) {
                            Text("\(completions)/\(assigned)")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                                .frame(width: 35, alignment: .trailing)
                            
                            if isComplete && assigned > 0 {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 16))
                            } else {
                                // Empty space to maintain alignment
                                Color.clear
                                    .frame(width: 16, height: 16)
                            }
                        }
                        .frame(width: 55)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - HELPER FUNCTIONS
    
    private func getCurrentMonth() -> Date {
        Calendar.current.date(byAdding: .month, value: currentMonthOffset, to: Date())!
    }
    
    private func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }
    
    private func isSameDay(_ d1: Date, _ d2: Date) -> Bool {
        Calendar.current.isDate(d1, inSameDayAs: d2)
    }
}

struct DayValue: Identifiable {
    let id = UUID()
    let day: Int
    let date: Date
}

extension CalendarView {
    
    func extractDates(for month: Date) -> [DayValue] {
        let calendar = Calendar.current
        
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        let daysInMonth = range.count
        
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        
        var days: [DayValue] = []
        
        for _ in 1..<firstWeekday {
            days.append(DayValue(day: -1, date: Date()))
        }
        
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(DayValue(day: day, date: date))
            }
        }
        
        return days
    }
}

#Preview {
    CalendarView(
        user: UserInfo(
            uid: "123",
            name: "Preview User",
            email: "test@email.com",
            groupID: "group1",
            photoURL: "",
            colorData: UIColor.systemPink.toData() ?? Data()
        )
    )
}
