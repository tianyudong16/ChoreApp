//
//  ChoresView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/12/25.
//

import SwiftUI

/// Main view for displaying all chores in the user's group
/// Navigated to from the HomeView when "View Chores" is tapped
struct ChoresView: View {
    
    // MARK: - Properties
    // ViewModel that handles data fetching and business logic
    @StateObject var viewModel = ChoresViewModel()
    
    // The current user's Firebase UID - passed from HomeView
    private let userID: String
    
    // MARK: - Initializer
    init(userID: String) {
        self.userID = userID
    }
    
    // MARK: - Body
    var body: some View {
        VStack {
            // MARK: Loading State
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading chores...")
                Spacer()
                
            // MARK: Error State
            } else if !viewModel.errorMessage.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    Text(viewModel.errorMessage)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                Spacer()
                
            // MARK: Empty State
            } else if viewModel.chores.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "checklist")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No chores yet!")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Tap the + button to add a chore")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
            // MARK: Chores List
            } else {
                List {
                    ForEach(viewModel.chores) { chore in
                        ChoreRowView(chore: chore) {
                            // Toggle completion when checkbox is tapped
                            viewModel.toggleChoreCompletion(chore)
                        }
                        // Swipe left to delete
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.deleteChore(chore)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("Chores")
        // Plus button in toolbar to add new chore
        .toolbar {
            Button {
                viewModel.showingNewChoreView = true
            } label: {
                Image(systemName: "plus")
            }
        }
        // Sheet for creating new chore
        .sheet(isPresented: $viewModel.showingNewChoreView) {
            NewChoreView(newChorePresented: $viewModel.showingNewChoreView)
        }
        // Load chores when view appears
        .onAppear {
            viewModel.loadChores(userID: userID)
        }
    }
}

// MARK: - ChoreRowView
/// A single row in the chores list displaying one chore's information
struct ChoreRowView: View {
    
    /// The chore data to display
    let chore: ChoreListItem
    
    /// Closure called when the completion checkbox is tapped
    let onToggleComplete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            
            // MARK: Completion Checkbox
            Button {
                onToggleComplete()
            } label: {
                Image(systemName: chore.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(chore.completed ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle()) // Prevents row highlight on tap
            
            // MARK: Chore Details
            VStack(alignment: .leading, spacing: 4) {
                
                // Chore name with strikethrough if completed
                Text(chore.name)
                    .font(.headline)
                    .strikethrough(chore.completed, color: .gray)
                    .foregroundColor(chore.completed ? .secondary : .primary)
                
                // Date and priority row
                HStack(spacing: 8) {
                    // Due date (if set)
                    if !chore.date.isEmpty {
                        Label(chore.date, systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Priority badge
                    ChorePriorityBadge(priority: chore.priorityLevel)
                }
                
                // Description (if exists)
                if !chore.description.trimmingCharacters(in: .whitespaces).isEmpty {
                    Text(chore.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Repetition info (if not "None")
                if chore.repetitionTime != "None" && !chore.repetitionTime.isEmpty {
                    Label(chore.repetitionTime, systemImage: "repeat")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        // Fade completed chores
        .opacity(chore.completed ? 0.6 : 1.0)
    }
}

// MARK: - ChorePriorityBadge
/// A small colored badge showing the chore's priority level
/// Renamed from PriorityBadge to avoid conflicts with DailyTasksView
struct ChorePriorityBadge: View {
    
    /// The priority level string ("low", "medium", or "high")
    let priority: String
    
    /// Returns the appropriate color for the priority level
    var color: Color {
        switch priority.lowercased() {
        case "high": return .red
        case "medium": return .orange
        default: return .green
        }
    }
    
    var body: some View {
        Text(priority.capitalized)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ChoresView(userID: "")
    }
}
