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
    
    // ViewModel that handles data fetching and business logic
    @StateObject var viewModel = ChoresViewModel()
    
    // The current user's Firebase UID - passed from HomeView
    private let userID: String
    
    // initializer for userID
    init(userID: String) {
        self.userID = userID
    }
    
    var body: some View {
        VStack {
            // loading state
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading chores...")
                Spacer()
                
            // error state
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
                
            // handles an empty state
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
                
            // chores list
            } else {
                List {
                    ForEach(viewModel.sortedChoreIDs, id: \.self) { choreID in
                        if let chore = viewModel.chores[choreID] {
                            ChoreRowView(chore: chore, choreID: choreID) {
                                viewModel.toggleChoreCompletion(choreID: choreID)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.deleteChore(choreID: choreID)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("Chores")
        .toolbar {
            Button {
                viewModel.showingNewChoreView = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $viewModel.showingNewChoreView) {
            NewChoreView(newChorePresented: $viewModel.showingNewChoreView)
        }
        .onAppear {
            viewModel.loadChores(userID: userID)
        }
    }
}

struct ChoreRowView: View {
    let chore: Chore
    let choreID: String
    let onToggleComplete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                onToggleComplete()
            } label: {
                Image(systemName: chore.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(chore.completed ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(chore.name)
                    .font(.headline)
                    .strikethrough(chore.completed, color: .gray)
                    .foregroundColor(chore.completed ? .secondary : .primary)
                
                HStack(spacing: 8) {
                    if !chore.date.isEmpty {
                        Label(chore.date, systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ChorePriorityBadge(priority: chore.priorityLevel)
                }
                
                if !chore.description.trimmingCharacters(in: .whitespaces).isEmpty {
                    Text(chore.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                if chore.repetitionTime != "None" && !chore.repetitionTime.isEmpty {
                    Label(chore.repetitionTime, systemImage: "repeat")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .opacity(chore.completed ? 0.6 : 1.0)
    }
}

struct ChorePriorityBadge: View {
    let priority: String
    
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
