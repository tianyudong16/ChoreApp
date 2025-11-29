//
//  DailyTasksView.swift
//  Chorely
//
//  Created by Brooke Tanner on 11/11/25.
//
//  Updated to integrate with Firebase and CalendarViewModel

import SwiftUI

// MARK: - DailyTasksView
/// Shows chores for a specific date
/// Can be opened from CalendarView or HomeView
struct DailyTasksView: View {
    
    // MARK: - Properties
    
    /// Current user's ID
    let userID: String
    
    /// The date to show chores for
    let selectedDate: Date
    
    /// Shared ViewModel (passed from CalendarView or created new)
    @ObservedObject var viewModel: CalendarViewModel
    
    /// Filter option for tasks
    @State private var selectedFilter: TaskFilter = .all
    
    /// Sort option for tasks
    @State private var sort: SortFilter = .due
    
    /// Environment dismiss action
    @Environment(\.dismiss) private var dismiss
    
    /// Track if we're in a sheet presentation
    private var isSheetPresentation: Bool
    
    // MARK: - Initializers
    
    /// Initialize with userID, date, and existing viewModel
    init(userID: String, selectedDate: Date, viewModel: CalendarViewModel, isSheetPresentation: Bool = false) {
        self.userID = userID
        self.selectedDate = selectedDate
        self.viewModel = viewModel
        self.isSheetPresentation = isSheetPresentation
    }
    
    // MARK: - Computed Properties
    
    /// Chores filtered for the selected date and current filter
    private var visibleTasks: [CalendarChore] {
        let dayChores = viewModel.choresForDate(selectedDate)
        
        // Apply filters
        var filteredChores = dayChores
        
        switch selectedFilter {
        case .all:
            break
        case .mine:
            filteredChores = filteredChores.filter { $0.assignedUsers.contains(userID) }
        case .roommates:
            filteredChores = filteredChores.filter { !$0.assignedUsers.contains(userID) && !$0.assignedUsers.isEmpty }
        }
        
        // Apply sorting
        switch sort {
        case .priorityLevel:
            return filteredChores.sorted {
                priorityRank($0.priorityLevel) < priorityRank($1.priorityLevel)
            }
        case .completion:
            return filteredChores.sorted { !$0.completed && $1.completed }
        case .due:
            return filteredChores.sorted { $0.date < $1.date }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Title and filter button
                HStack {
                    // Show back button only when in sheet presentation (from Calendar)
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
                
                // Selected date display
                Text(selectedDate.formatted(date: .complete, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 4)
                
                // Filter chips
                FilterChips(selection: $selectedFilter)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                Divider()
                
                // Content
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading tasks...")
                    Spacer()
                } else if visibleTasks.isEmpty {
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
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(visibleTasks) { task in
                                TaskCard(task: task, viewModel: viewModel)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            // Load data when view appears
            viewModel.loadData(userID: userID)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Convert priority string to rank for sorting
    private func priorityRank(_ priority: String) -> Int {
        switch priority.lowercased() {
        case "high": return 0
        case "medium": return 1
        default: return 2
        }
    }
}

// MARK: - Supporting Types

enum TaskFilter: String, CaseIterable, Identifiable {
    case all = "House", mine = "Mine", roommates = "Roommates"
    var id: String { rawValue }
}

enum SortFilter: String, CaseIterable, Identifiable {
    case priorityLevel = "Priority Level"
    case completion = "Completion"
    case due = "Due Date"

    var id: String { self.rawValue }
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

private struct TaskCard: View {
    let task: CalendarChore
    let viewModel: CalendarViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.name)
                        .font(.headline)
                        .strikethrough(task.completed, color: .gray)
                        .foregroundColor(task.completed ? .secondary : .primary)
                    
                    HStack(spacing: 8) {
                        Label(task.dateString, systemImage: "calendar.badge.clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        PriorityTag(priority: task.priorityLevel)
                    }
                }
                Spacer()
                
                // Completion checkbox
                Button {
                    withAnimation(.snappy) {
                        viewModel.toggleChoreCompletion(task)
                    }
                } label: {
                    Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(task.completed ? .green : .gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Description
            if !task.description.isEmpty && task.description != " " {
                Text(task.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }
            
            // Footer - Assignees
            if !task.assignedUsers.isEmpty {
                HStack {
                    Text("Assigned to:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ForEach(task.assignedUsers.prefix(3), id: \.self) { userId in
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
                    
                    if task.assignedUsers.count > 3 {
                        Text("+\(task.assignedUsers.count - 3)")
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
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.background)
                .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(task.priorityColor.opacity(0.45), lineWidth: 1)
        )
        .opacity(task.completed ? 0.6 : 1.0)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview
#Preview {
    DailyTasksView(userID: "test", selectedDate: Date(), viewModel: CalendarViewModel())
}
