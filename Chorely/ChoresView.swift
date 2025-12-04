//
//  ChoresView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/12/25.
//

import SwiftUI

// Main view for displaying all chores in the user's group
// Shows a list of chores that can be checked off, deleted via swipe, or filtered
struct ChoresView: View {
    
    // ViewModel handles data fetching and business logic
    @StateObject private var viewModel: ChoresViewModel
    
    // User ID for Firebase queries
    private let userID: String
    
    init(userID: String) {
        self.userID = userID
        // Initialize StateObject with new ViewModel instance
        _viewModel = StateObject(wrappedValue: ChoresViewModel())
    }
    
    var body: some View {
        VStack {
            // Show different content based on loading/error/empty/data states
            if viewModel.isLoading {
                // Loading state
                Spacer()
                ProgressView("Loading chores...")
                Spacer()
                
            } else if !viewModel.errorMessage.isEmpty {
                // Error state
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
                
            } else if viewModel.chores.isEmpty {
                // Empty state - no chores yet
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
                
            } else {
                // Data state - show list of chores
                List {
                    // Iterate through sorted chore IDs
                    ForEach(viewModel.sortedChoreIDs, id: \.self) { choreID in
                        if let chore = viewModel.chores[choreID] {
                            // Display each chore row
                            ChoreRowView(
                                chore: chore,
                                choreID: choreID,
                                onToggleComplete: {
                                    viewModel.toggleChoreCompletion(choreID: choreID)
                                },
                                onDeleteSingle: {
                                    viewModel.deleteChore(choreID: choreID)
                                },
                                onDeleteFuture: {
                                    viewModel.deleteFutureOccurrences(
                                        seriesId: chore.seriesId,
                                        fromDate: chore.date,
                                        choreID: choreID
                                    )
                                }
                            )
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
            viewModel.fetchUserAndLoadChores(userID: userID)
        }
    }
}

// Single row in the chores list displaying one chore
struct ChoreRowView: View {
    let chore: Chore
    let choreID: String
    let onToggleComplete: () -> Void
    let onDeleteSingle: () -> Void
    let onDeleteFuture: () -> Void
    
    @State private var showDeleteFutureAlert = false
    
    // Check if this is part of a repeating series
    private var isRepeating: Bool {
        !chore.seriesId.isEmpty && chore.repetitionTime != "None"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Completion checkbox
            Button {
                onToggleComplete()
            } label: {
                Image(systemName: chore.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(chore.completed ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle()) // Prevents row highlight on tap
            
            // Chore details
            VStack(alignment: .leading, spacing: 4) {
                // Chore name with strikethrough if completed
                Text(chore.name)
                    .font(.headline)
                    .strikethrough(chore.completed, color: .gray)
                    .foregroundColor(chore.completed ? .secondary : .primary)
                
                // Date and priority row
                HStack(spacing: 8) {
                    if !chore.date.isEmpty {
                        Label(chore.date, systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ChorePriorityBadge(priority: chore.priorityLevel)
                }
                
                // Optional description
                if !chore.description.trimmingCharacters(in: .whitespaces).isEmpty {
                    Text(chore.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Repetition info if set
                if chore.repetitionTime != "None" && !chore.repetitionTime.isEmpty {
                    Label(chore.repetitionTime, systemImage: "repeat")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            // 3-dot menu button
            Menu {
                Button(role: .destructive) {
                    onDeleteSingle()
                } label: {
                    Label("Delete This Occurrence", systemImage: "trash")
                }
                
                if isRepeating {
                    Button(role: .destructive) {
                        showDeleteFutureAlert = true
                    } label: {
                        Label("Delete All Future Occurrences", systemImage: "trash.fill")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .padding(8)
            }
        }
        .padding(.vertical, 8)
        .opacity(chore.completed ? 0.6 : 1.0)
        // Confirmation alert for deleting all future
        .alert("Delete All Future Occurrences?", isPresented: $showDeleteFutureAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete All", role: .destructive) {
                onDeleteFuture()
            }
        } message: {
            Text("This will delete this chore and all future occurrences in this series. This cannot be undone.")
        }
    }
}

// Small colored badge showing chore priority level
struct ChorePriorityBadge: View {
    let priority: String
    
    // Color based on priority
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

#Preview {
    NavigationStack {
        ChoresView(userID: "")
    }
}
