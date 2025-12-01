//
//  DailyTasksView.swift
//  Chorely
//
//  Created by Brooke Tanner on 11/11/25.
//

import SwiftUI

// View that shows all chores for a specific date
// Can be opened from CalendarView (as sheet) or HomeView (via navigation)
struct DailyTasksView: View {
    
    // Required parameters
    let userID: String                        // Current user's ID
    let selectedDate: Date                    // Date to show chores for
    @ObservedObject var viewModel: CalendarViewModel // Shared ViewModel from parent
    
    // Local state for filtering and sorting
    @State private var selectedFilter: TaskFilter = .all // Filter: House/Mine/Roommates
    @State private var sort: SortFilter = .due           // Sort: Priority/Completion/Due Date
    
    // Environment for dismissing the view
    @Environment(\.dismiss) private var dismiss
    
    // Whether this view is presented as a sheet (shows back button)
    private var isSheetPresentation: Bool
    
    init(userID: String, selectedDate: Date, viewModel: CalendarViewModel, isSheetPresentation: Bool = false) {
        self.userID = userID
        self.selectedDate = selectedDate
        self.viewModel = viewModel
        self.isSheetPresentation = isSheetPresentation
    }
    
    // Computed property: chores filtered and sorted based on user selections
    private var visibleChores: [(id: String, chore: Chore)] {
        // Get chores for the selected date
        var dayChores = viewModel.choresForDate(selectedDate)
        
        // Apply filter
        switch selectedFilter {
        case .all:
            break // Show all chores
        case .mine:
            // Only chores assigned to current user
            dayChores = dayChores.filter { $0.chore.assignedUsers.contains(userID) }
        case .roommates:
            // Only chores assigned to others
            dayChores = dayChores.filter { !$0.chore.assignedUsers.contains(userID) && !$0.chore.assignedUsers.isEmpty }
        }
        
        // Apply sorting
        switch sort {
        case .priorityLevel:
            return dayChores.sorted { viewModel.priorityRank($0.chore.priorityLevel) < viewModel.priorityRank($1.chore.priorityLevel) }
        case .completion:
            return dayChores.sorted { !$0.chore.completed && $1.chore.completed }
        case .due:
            return dayChores.sorted { $0.chore.date < $1.chore.date }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection
                dateDisplay
                
                // Filter chips
                FilterChips(selection: $selectedFilter)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                Divider()
                
                contentSection
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            // Load data when view appears
            viewModel.loadData(userID: userID)
        }
    }
    
    // Header with title and sort menu
    private var headerSection: some View {
        HStack {
            // Back button (only in sheet presentation)
            if isSheetPresentation {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                        .padding(.trailing, 4)
                }
            }
            
            Text("Daily Tasks")
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            // Sort menu
            Menu {
                Text("Sort Tasks By")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Divider()
                
                Picker("", selection: $sort) {
                    ForEach(SortFilter.allCases) { sortOption in
                        Text(sortOption.rawValue).tag(sortOption)
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
    }
    
    // Display the selected date
    private var dateDisplay: some View {
        Text(selectedDate.formatted(date: .complete, time: .omitted))
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.horizontal)
            .padding(.top, 4)
    }
    
    // Shows loading, empty state, or task list
    private var contentSection: some View {
        Group {
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading tasks...")
                Spacer()
            } else if visibleChores.isEmpty {
                emptyStateView
            } else {
                tasksList
            }
        }
    }
    
    // Displayed when no chores exist for the selected date
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)
                .padding(.top, 40)

            Text("No tasks for this date!")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("All tasks are completed or no chores scheduled")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    // Scrollable list of task cards
    private var tasksList: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(visibleChores, id: \.id) { item in
                    TaskCard(choreID: item.id, chore: item.chore, viewModel: viewModel)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
    }
}

// Filter options for tasks
enum TaskFilter: String, CaseIterable, Identifiable {
    case all = "House"
    case mine = "Mine"
    case roommates = "Roommates"
    var id: String { rawValue }
}

// Sort options for tasks
enum SortFilter: String, CaseIterable, Identifiable {
    case priorityLevel = "Priority Level"
    case completion = "Completion"
    case due = "Due Date"
    var id: String { self.rawValue }
}

// Horizontal scrolling filter chips
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

// Small colored tag showing priority level
private struct PriorityTag: View {
    let priority: String
    
    var body: some View {
        let color: Color = {
            switch priority.lowercased() {
            case "high": return .red
            case "medium": return .orange
            default: return .green
            }
        }()
        
        Text(priority.capitalized)
            .font(.caption2).bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.14))
            .foregroundStyle(color)
            .clipShape(Capsule())
            .accessibilityLabel("Priority \(priority)")
    }
}

// Card displaying a single task with all its details
private struct TaskCard: View {
    let choreID: String
    let chore: Chore
    let viewModel: CalendarViewModel
    
    // Color for the card border based on priority
    private var priorityColor: Color {
        switch chore.priorityLevel.lowercased() {
        case "high": return .red
        case "medium": return .orange
        default: return .green
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerRow
            descriptionSection
            assigneesSection
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.background)
                .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(priorityColor.opacity(0.45), lineWidth: 1)
        )
        .opacity(chore.completed ? 0.6 : 1.0)
        .accessibilityElement(children: .combine)
    }
    
    // Header with name, date, priority, and completion checkbox
    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(chore.name)
                    .font(.headline)
                    .strikethrough(chore.completed, color: .gray)
                    .foregroundColor(chore.completed ? .secondary : .primary)
                
                HStack(spacing: 8) {
                    Label(chore.date, systemImage: "calendar.badge.clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    PriorityTag(priority: chore.priorityLevel)
                }
            }
            Spacer()
            
            // Completion toggle button
            Button {
                withAnimation(.snappy) {
                    viewModel.toggleChoreCompletion(choreID: choreID)
                }
            } label: {
                Image(systemName: chore.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(chore.completed ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // Optional description text
    private var descriptionSection: some View {
        Group {
            if !chore.description.isEmpty && chore.description != " " {
                Text(chore.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }
        }
    }
    
    // Shows assigned users or "Unassigned" label
    private var assigneesSection: some View {
        Group {
            if !chore.assignedUsers.isEmpty {
                HStack {
                    Text("Assigned to:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    // Show up to 3 assignee chips
                    ForEach(chore.assignedUsers.prefix(3), id: \.self) { userId in
                        let memberName = viewModel.nameForUser(userId)
                        let memberColor = viewModel.colorForUser(userId)
                        
                        Text(memberName)
                            .font(.caption)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(memberColor.opacity(0.2))
                            .foregroundStyle(memberColor)
                            .clipShape(Capsule())
                    }
                    
                    // Show +N if more than 3 assignees
                    if chore.assignedUsers.count > 3 {
                        Text("+\(chore.assignedUsers.count - 3)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                HStack {
                    Text("Unassigned")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    DailyTasksView(userID: "test", selectedDate: Date(), viewModel: CalendarViewModel())
}
