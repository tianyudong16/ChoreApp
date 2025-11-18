//
//  DailyTaskView.swift
//  Chorely
//
//  Created by Brooke Tanner on 11/11/25.
//
// example UI layout, will replace variables with data


import SwiftUI


public struct DailyTasksView: View {
    @State private var selectedFilter: TaskFilter = .all
    @State private var showFilterSheet = false
    @State private var sort: SortFilter = .due
    
    //in place of data for now
    @State private var tasks: [TaskItem] = [
            TaskItem(name: "Dishes", assignee: "Me", dueLabel: "Due Today",  priority: .med),
            TaskItem(name: "Bathroom", assignee: "Roommate", dueLabel: "Due Tomorrow", priority: .high),
            TaskItem(name: "Trash", assignee: "Roommate", dueLabel: "Due Friday", priority: .low)
        ]

        public init() {}


    @Environment(\.dismiss) private var dismiss
    
    //for the filtering and sorting the chores
    private var visibleTasks: [TaskItem] {
            var filtered = tasks
        switch selectedFilter {
                case .all:
                    break
                case .mine:
                    filtered = filtered.filter { $0.assignee == "Me" }
                case .roommates:
                    filtered = filtered.filter { $0.assignee == "Roommate" }
                }
        switch sort {
            //sort by priority (high-low)
                case .priorityLevel:
                    filtered.sort { $0.priority.sortRank < $1.priority.sortRank }
            //sort by completion (completed at bottom) this doesn't work yet
                case .completion:
                    filtered.sort { !$0.isCompleted && $1.isCompleted }
            //sort by due date (soonest-latest)
                case .due:
                    filtered.sort { $0.dueSortRank < $1.dueSortRank }
                }
                
                return filtered
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
                    LazyVStack(spacing: 14) {
                        ForEach(visibleTasks) { task in
                            TaskCard(task: task)
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
    let task: TaskItem
    @State private var isDone: Bool = false
    
    init(task: TaskItem) {
        self.task = task
        _isDone = State(initialValue: task.isCompleted)
    }
    
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
                    Badge(text: "Daily")
                    Badge(text: "End")
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
                    withAnimation(.snappy) { isDone.toggle() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isDone ? "checkmark.square.fill" : "square")
                        Text("Mark Done")
                    }
                    .font(.subheadline)
                }
                .buttonStyle(.plain)
                .foregroundStyle(isDone ? .green : .primary)
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
