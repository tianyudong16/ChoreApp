//
//  CalendarViewModel.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/29/25.
//

import Foundation
import FirebaseFirestore
import SwiftUI

// Filter options for viewing chores on the calendar
// Users can filter to see all house chores, just their own, or just roommates' chores
enum ChoreFilter: String, CaseIterable, Identifiable {
    case house = "House"
    case mine = "Mine"
    case roommates = "Roommates"
    
    var id: String { rawValue }
}

// Stores information about a group member for display purposes
// Used to show colored dots on calendar and assignee names on chores
struct GroupMemberInfo: Identifiable {
    let id: String          // Firebase UID
    let name: String        // Display name
    let color: Color        // SwiftUI color for UI elements
    let colorString: String // Original color name from Firebase
}

// ViewModel that manages data for CalendarView and DailyTasksView
// Handles fetching chores and group members from Firebase
// Uses real-time listeners to keep data in sync
@MainActor
class CalendarViewModel: ObservableObject {
    
    // Published properties automatically update the UI when changed
    @Published var chores: [String: Chore] = [:]       // Dictionary mapping documentID to Chore
    @Published var groupMembers: [GroupMemberInfo] = [] // All members in the user's group
    @Published var currentUserID: String = ""           // Currently logged in user's ID
    @Published var currentUserName: String = ""         // Currently logged in user's name
    @Published var selectedFilter: ChoreFilter = .house // Current filter selection
    @Published var isLoading = true                     // Shows loading spinner when true
    @Published var errorMessage = ""                    // Error message to display
    
    // Private properties for Firebase operations
    private var groupKey: String?                           // User's group identifier
    private var choresListener: ListenerRegistration?       // Real-time listener for chores
    private var membersListener: ListenerRegistration?      // Real-time listener for members
    
    // Returns all chore document IDs as an array
    var choreIDs: [String] {
        Array(chores.keys)
    }
    
    // Returns chore IDs filtered based on the selected filter option
    // - house: returns all chores
    // - mine: returns only chores assigned to current user
    // - roommates: returns chores assigned to others (not current user)
    var filteredChoreIDs: [String] {
        switch selectedFilter {
        case .house:
            return choreIDs
        case .mine:
            return choreIDs.filter { chores[$0]?.assignedUsers.contains(currentUserID) == true }
        case .roommates:
            return choreIDs.filter {
                guard let chore = chores[$0] else { return false }
                return !chore.assignedUsers.contains(currentUserID) && !chore.assignedUsers.isEmpty
            }
        }
    }
    
    // Returns all chores scheduled for a specific date
    // Returns tuples of (documentID, Chore) for easy iteration
    func choresForDate(_ date: Date) -> [(id: String, chore: Chore)] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Filter chores that match the given date
        return filteredChoreIDs.compactMap { id in
            guard let chore = chores[id],
                  let choreDate = dateFormatter.date(from: chore.date),
                  calendar.isDate(choreDate, inSameDayAs: date) else { return nil }
            return (id, chore)
        }
    }
    
    // Returns unique colors for all assignees of chores on a given date
    // Used to display colored dots on calendar day cells
    func assigneeColorsForDate(_ date: Date) -> [Color] {
        let dayChores = choresForDate(date)
        var colors: [Color] = []
        
        // Collect unique colors from all assigned users
        for (_, chore) in dayChores {
            for userID in chore.assignedUsers {
                if let member = groupMembers.first(where: { $0.id == userID }) {
                    if !colors.contains(member.color) {
                        colors.append(member.color)
                    }
                }
            }
        }
        
        // Default to gray if chores exist but no specific assignees
        if colors.isEmpty && !dayChores.isEmpty {
            colors.append(.gray)
        }
        
        return colors
    }
    
    // Checks if any chores exist for a given date
    func dateHasChores(_ date: Date) -> Bool {
        return !choresForDate(date).isEmpty
    }
    
    // Finds a group member by their Firebase UID
    func getMember(byID id: String) -> GroupMemberInfo? {
        return groupMembers.first(where: { $0.id == id })
    }
    
    // Returns the color associated with a user ID
    // Falls back to gray if user not found
    func colorForUser(_ userID: String) -> Color {
        return getMember(byID: userID)?.color ?? .gray
    }
    
    // Returns the display name for a user ID
    // Falls back to "Unknown" if user not found
    func nameForUser(_ userID: String) -> String {
        return getMember(byID: userID)?.name ?? "Unknown"
    }
    
    // Main entry point for loading data
    // Fetches user data, then sets up real-time listeners for chores and members
    func loadData(userID: String) {
        self.currentUserID = userID
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                // Fetch user data using FirebaseInterface
                let userData = try await FirebaseInterface.shared.getUserData(uid: userID)
                let keys = FirebaseInterface.shared.extractGroupKey(from: userData)
                
                self.currentUserName = userData["Name"] as? String ?? "User"
                
                // Verify user has a group key
                guard let keyString = keys.string else {
                    self.errorMessage = "No group key found"
                    self.isLoading = false
                    return
                }
                
                self.groupKey = keyString
                
                // Set up real-time listeners for chores and group members
                setupChoresListener(groupKey: keyString)
                if let intKey = keys.int {
                    setupMembersListener(groupKey: intKey)
                }
                
            } catch {
                self.errorMessage = "Error loading user: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // Toggles a chore's completion status
    // Uses markComplete when checking off, editChore when unchecking
    func toggleChoreCompletion(choreID: String) {
        guard let groupKey = groupKey,
              let chore = chores[choreID] else { return }
        
        Task {
            if chore.completed {
                // Unchecking: create updated chore with completed = false
                let updatedChore = Chore(
                    checklist: chore.checklist,
                    date: chore.date,
                    day: chore.day,
                    description: chore.description,
                    monthlyRepeatByDate: chore.monthlyRepeatByDate,
                    monthlyRepeatByWeek: chore.monthlyRepeatByWeek,
                    name: chore.name,
                    priorityLevel: chore.priorityLevel,
                    repetitionTime: chore.repetitionTime,
                    timeLength: chore.timeLength,
                    assignedUsers: chore.assignedUsers,
                    completed: false,
                    votes: chore.votes,
                    voters: chore.voters,
                    proposal: chore.proposal
                )
                
                // Use editChore to update the chore in Firebase
                editChore(documentId: choreID, chore: updatedChore, groupKey: groupKey) { success in
                    if success {
                        print("Chore unchecked successfully")
                    }
                }
            } else {
                // Checking off: use markComplete which also records who completed it
                await FirebaseInterface.shared.markComplete(
                    userName: currentUserName,
                    choreId: choreID,
                    groupKey: groupKey
                )
            }
        }
    }
    
    // Deletes a chore from Firebase
    func deleteChore(choreID: String) {
        guard let groupKey = groupKey else { return }
        FirebaseInterface.shared.deleteChore(groupKey: groupKey, choreId: choreID)
    }
    
    // Sets up a real-time listener for chores in the user's group
    // The listener automatically updates the chores dictionary when changes occur
    private func setupChoresListener(groupKey: String) {
        // Remove any existing listener to prevent duplicates
        choresListener?.remove()
        
        // Set up new listener using FirebaseInterface
        choresListener = FirebaseInterface.shared.addChoresListener(groupKey: groupKey) { [weak self] documents, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error loading chores: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = documents else {
                    self.chores = [:]
                    return
                }
                
                // Parse documents into Chore objects
                self.chores = self.readChoreDocuments(documents)
                print("Loaded \(self.chores.count) chores for calendar")
            }
        }
    }
    
    // Sets up a real-time listener for group members
    // Updates groupMembers array when members are added/removed/changed
    private func setupMembersListener(groupKey: Int) {
        membersListener?.remove()
        
        membersListener = FirebaseInterface.shared.addGroupMembersListener(groupKey: groupKey) { [weak self] documents, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("Error loading group members: \(error)")
                    return
                }
                
                guard let documents = documents else {
                    self.groupMembers = []
                    return
                }
                
                self.groupMembers = self.readMemberDocuments(documents)
                print("Loaded \(self.groupMembers.count) group members")
            }
        }
    }
    
    // Converts Firestore documents into a dictionary of Chore objects
    // Maps document ID to Chore for easy lookup
    private func readChoreDocuments(_ documents: [QueryDocumentSnapshot]) -> [String: Chore] {
        var result: [String: Chore] = [:]
        
        for doc in documents {
            let data = doc.data()
            
            // Name is required - skip documents without it
            guard let name = data["Name"] as? String else { continue }
            
            // Create Chore object with all fields from Firebase
            let chore = Chore(
                checklist: data["Checklist"] as? Bool ?? false,
                date: data["Date"] as? String ?? "",
                day: data["Day"] as? String ?? "",
                description: data["Description"] as? String ?? " ",
                monthlyRepeatByDate: data["MonthlyRepeatByDate"] as? Bool ?? false,
                monthlyRepeatByWeek: data["MonthlyRepeatByWeek"] as? String ?? " ",
                name: name,
                priorityLevel: data["PriorityLevel"] as? String ?? "low",
                repetitionTime: data["RepetitionTime"] as? String ?? "None",
                timeLength: data["TimeLength"] as? Int ?? 0,
                assignedUsers: data["assignedUsers"] as? [String] ?? [],
                completed: data["completed"] as? Bool ?? false,
                votes: data["votes"] as? Int ?? 0,
                voters: data["voters"] as? [String] ?? [],
                proposal: data["proposal"] as? Bool ?? false
            )
            result[doc.documentID] = chore
        }
        
        return result
    }
    
    // Converts Firestore documents into GroupMemberInfo objects
    private func readMemberDocuments(_ documents: [QueryDocumentSnapshot]) -> [GroupMemberInfo] {
        return documents.compactMap { doc -> GroupMemberInfo? in
            let data = doc.data()
            guard let name = data["Name"] as? String else { return nil }
            
            let colorString = data["color"] as? String ?? "Green"
            let color = colorFromString(colorString)
            
            return GroupMemberInfo(
                id: doc.documentID,
                name: name,
                color: color,
                colorString: colorString
            )
        }
    }
    
    // Converts a color name string to a SwiftUI Color
    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "cyan": return .cyan
        case "mint": return .mint
        case "teal": return .teal
        case "indigo": return .indigo
        default: return .green
        }
    }
    
    // Converts priority string to numeric rank for sorting
    // Lower number = higher priority (high=0, medium=1, low=2)
    func priorityRank(_ priority: String) -> Int {
        switch priority.lowercased() {
        case "high": return 0
        case "medium": return 1
        default: return 2
        }
    }
    
    // Cleanup: remove Firebase listeners when ViewModel is deallocated
    // Prevents memory leaks and unnecessary network traffic
    deinit {
        choresListener?.remove()
        membersListener?.remove()
    }
}
