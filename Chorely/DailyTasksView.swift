//
//  DailyTaskView.swift
//  Chorely
//
//  Created by Brooke Tanner on 11/11/25.
//
// example UI layout, will replace  with data
// I (Brooke)  realized this should only show chores due the day of so I'm going to change it


import SwiftUI


public struct DailyTasksView: View {
    //initially shows all chores
    @State private var selectedFilter: TaskFilter = .all
    @State private var showFilterSheet = false
    //initially sorts chores by due
    @State private var sort: SortFilter = .due
    
    //in place of data for now
    @State private var tasks: [TaskItem] = [
            TaskItem(name: "Dishes", assignee: "Me", dueLabel: "Due Today",  priority: .med),
            TaskItem(name: "Bathroom", assignee: "Roommate", dueLabel: "Due Tomorrow", priority: .high),
            TaskItem(name: "Trash", assignee: "Roommate", dueLabel: "Due Friday", priority: .low)
        ]

        public init() {}


    @Environment(\.dismiss) private var dismiss
    
    //for filtering and sorting the chores
    //note: I'm using indices for this so I can update the tasks directly so when they are marked as completed it is reflected (for each loop only gives copies/doesn't modify chore directly)
    private var visibleTaskIndices: [Int] {
        // only chores due today
        var indices = tasks.indices.filter { tasks[$0].isDueToday }
        
        // filter by chip selection
        switch selectedFilter {
            //house: users chores and roommates chores
        case .all:
            break
            //only users chores
        case .mine:
            indices = indices.filter { tasks[$0].assignee == "Me" }
            //only roommates chores (potentially get rid of this)
        case .roommates:
            indices = indices.filter { tasks[$0].assignee == "Roommate" }
        }
        
        // sorting
        switch sort {
        case .priorityLevel:
            indices.sort { tasks[$0].priority.sortRank < tasks[$1].priority.sortRank }
            //this shows completed chores at the bottom but will change it so there are 2 options: one to only show uncompleted chores and one to show all chores sorted like this
        case .completion:
            indices.sort { !tasks[$0].isCompleted && tasks[$1].isCompleted }
            //will change due to mean time its due instead of day
        case .due:
            indices.sort { tasks[$0].dueSortRank < tasks[$1].dueSortRank }
        }
        
        return indices
    }
        
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Title and filter button
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                            .padding(.trailing, 4)
                    }
                    
                    Text("Daily Tasks")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    //filter button at top right
                    Menu {
                        Text("Sort Tasks By")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Divider()
                        
                        Picker("", selection: $sort) {
                            ForEach(SortFilter.allCases) { sortOption in
                                Text(sortOption.rawValue)
                                    .tag(sortOption)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                
                // Filter chores: house (all chores) / mine / roommates
                FilterChips(selection: $selectedFilter)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                Divider()
                ScrollView {
                    // if everything due today is marked complete this will show
                    if visibleTaskIndices.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.green)
                                .padding(.top, 40)

                            Text("All tasks for today are done!")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 300)
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(visibleTaskIndices, id: \.self) { index in
                                TaskCard(task: $tasks[index])
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
    }
}



private enum TaskFilter: String, CaseIterable, Identifiable {
    case all = "House", mine = "Mine", roommates = "Roommates"
    var id: String { rawValue }
}

enum SortFilter: String, CaseIterable, Identifiable {
    case priorityLevel = "Priority Level"
    case completion = "Completion"
    case due = "Due Date"

    var id: String { self.rawValue }
}

private struct TaskItem: Identifiable {
    let id = UUID()
    let name: String
    let assignee: String
    let dueLabel: String
    let priority: Priority
    var isCompleted: Bool = false
    
    //to get chores due today
    var isDueToday: Bool {
        dueLabel.lowercased().contains("today")
    }
    
    var dueSortRank: Int {
        let lower = dueLabel.lowercased()
        
        // associating days with numbers so they can be sorted, will probably have to change this because it wont work if today is friday etc
        if lower.contains("today") { return 0 }
        if lower.contains("tomorrow") { return 1 }
        if lower.contains("fri") || lower.contains("saturday") || lower.contains("sunday") {
            return 2
        }
        
        return 3
    }
}


private struct FilterChips: View {
    @Binding var selection: TaskFilter
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            //header for top bar
            HStack(spacing: 10) {
                ForEach(TaskFilter.allCases, id: \.self) { f in
                    Button { selection = f } label: {
                        Text(f.rawValue)
                            .font(.subheadline).bold()
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(selection == f ? Color.accentColor.opacity(0.15) : Color(.systemGray6))
                            .foregroundStyle(selection == f ? Color.accentColor : .primary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .accessibilityLabel("Current filter \(selection.rawValue)")
    }
}

private enum Priority: String {
    case low = "Low", med = "Med", high = "High"
    
    var sortRank: Int {
        switch self {
        case .high: return 0
        case .med:  return 1
        case .low:  return 2
        }
    }
}


private struct PriorityTag: View {
    //associates a color with a priority and shows it on task card
    let priority: Priority
    var body: some View {
        let color: Color = switch priority {
        case .low:  .green
        case .med:  .orange
        case .high: .red
        }
        Text(priority.rawValue.uppercased())
            .font(.caption2).bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.14))
            .foregroundStyle(color)
            .clipShape(Capsule())
            .accessibilityLabel("Priority \(priority.rawValue)")
    }
}

private struct TaskCard: View {
    @Binding var task: TaskItem
    var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.name).font(.headline)
                        HStack(spacing: 8) {
                            Label(task.dueLabel, systemImage: "calendar.badge.clock")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            PriorityTag(priority: task.priority)
                        }
                    }
                    Spacer()
                    VStack(spacing: 6) {
                        //Badge(text: "Daily")
                        //Badge(text: "End")
                    }
                }
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(colorForPriority(task.priority).opacity(0.25))
                    .frame(height: 110)
                
                // Footer
                HStack {
                    Label(task.assignee, systemImage: "person.fill")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.snappy) {
                            task.isCompleted.toggle()   // 👈 updates the real data now
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                            Text("Mark Done")
                        }
                        .font(.subheadline)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(task.isCompleted ? .green : .primary)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(colorForPriority(task.priority).opacity(0.45), lineWidth: 1)
            )
            .accessibilityElement(children: .combine)
        }
        
        private func colorForPriority(_ priority: Priority) -> Color {
            switch priority {
            case .high: return .red
            case .med:  return .yellow
            case .low:  return .green
            }
        }
    }

private struct Badge: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption2).bold()
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Color(.systemGray6))
            .clipShape(Capsule())
    }
}




#Preview {
    DailyTasksView()
}
