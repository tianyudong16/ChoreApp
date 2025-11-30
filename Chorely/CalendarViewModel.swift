//
//  CalendarViewModel.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/29/25.
//

import Foundation
import FirebaseFirestore
import SwiftUI

// Filter options for viewing chores
enum ChoreFilter: String, CaseIterable, Identifiable {
    case house = "House" // All chores in the group
    case mine = "Mine" // Only current user's chores
    case roommates = "Roommates" // Only roommates' chores
    
    var id: String { rawValue }
}

// Represents a chore with all info needed for calendar display
struct CalendarChore: Identifiable {
    let id: String
    let name: String
    let description: String
    let date: Date // Actual Date object for comparison
    let dateString: String // Original string from Firebase
    let day: String
    let priorityLevel: String
    let repetitionTime: String
    let timeLength: Int
    let assignedUsers: [String] // User IDs assigned to this chore
    var completed: Bool
    
    // Priority color for display
    var priorityColor: Color {
        switch priorityLevel.lowercased() {
        case "high": return .red
        case "medium": return .orange
        default: return .green
        }
    }
}

// Stores group member info including their chosen color
struct GroupMemberInfo: Identifiable {
    let id: String // User's Firebase UID
    let name: String
    let color: Color
    let colorString: String // Original color name from Firebase
}

// ViewModel for CalendarView and DailyTasksView
// Handles fetching chores and group members using FirebaseInterface
@MainActor
class CalendarViewModel: ObservableObject {
    @Published var chores: [CalendarChore] = [] // All chores for the group
    @Published var groupMembers: [GroupMemberInfo] = [] // All members with colors
    @Published var currentUserID: String = "" // Current logged-in user
    @Published var selectedFilter: ChoreFilter = .house // Current filter selection
    @Published var isLoading = true
    @Published var errorMessage = ""
    
    
    private var groupKey: String?
    private var groupKeyInt: Int?
    private var choresListener: ListenerRegistration?
    private var membersListener: ListenerRegistration?
    
    // Returns chores filtered by the selected filter
    var filteredChores: [CalendarChore] {
        switch selectedFilter {
        case .house:
            return chores
        case .mine:
            return chores.filter { $0.assignedUsers.contains(currentUserID) }
        case .roommates:
            return chores.filter { !$0.assignedUsers.contains(currentUserID) && !$0.assignedUsers.isEmpty }
        }
    }
    
    // Returns chores for a specific date
    func choresForDate(_ date: Date) -> [CalendarChore] {
        let calendar = Calendar.current
        return filteredChores.filter { chore in
            calendar.isDate(chore.date, inSameDayAs: date)
        }
    }
    
    // Returns all assignee colors for a specific date (for calendar dots)
    func assigneeColorsForDate(_ date: Date) -> [Color] {
        let dayChores = choresForDate(date)
        var colors: [Color] = []
        
        for chore in dayChores {
            for userID in chore.assignedUsers {
                if let member = groupMembers.first(where: { $0.id == userID }) {
                    if !colors.contains(member.color) {
                        colors.append(member.color)
                    }
                }
            }
        }
        
        // If no specific assignees, return a default color
        if colors.isEmpty && !dayChores.isEmpty {
            colors.append(.gray)
        }
        
        return colors
    }
    
    // Checks if a date has any chores
    func dateHasChores(_ date: Date) -> Bool {
        return !choresForDate(date).isEmpty
    }
    
    // Get member info by ID
    func getMember(byID id: String) -> GroupMemberInfo? {
        return groupMembers.first(where: { $0.id == id })
    }
    
    // Get color for a user ID
    func colorForUser(_ userID: String) -> Color {
        return getMember(byID: userID)?.color ?? .gray
    }
    
    // Get name for a user ID
    func nameForUser(_ userID: String) -> String {
        return getMember(byID: userID)?.name ?? "Unknown"
    }
    
    // Methods
    // Initialize data loading with user ID
    func loadData(userID: String) {
        self.currentUserID = userID
        isLoading = true
        errorMessage = ""
        
        // Use FirebaseInterface to get user data and groupKey
        Task {
            do {
                let userData = try await FirebaseInterface.shared.getUserData(uid: userID)
                
                // Extract groupKey (could be Int or String)
                var groupKeyString: String?
                var groupKeyInteger: Int?
                
                if let intKey = userData["groupKey"] as? Int {
                    groupKeyString = String(intKey)
                    groupKeyInteger = intKey
                } else if let strKey = userData["groupKey"] as? String {
                    groupKeyString = strKey
                    groupKeyInteger = Int(strKey)
                }
                
                guard let key = groupKeyString else {
                    self.errorMessage = "No group key found"
                    self.isLoading = false
                    return
                }
                
                self.groupKey = key
                self.groupKeyInt = groupKeyInteger
                
                // Set up listeners using direct Firestore (since FirebaseInterface doesn't have listener methods)
                self.setupChoresListener(groupKey: key)
                if let intKey = groupKeyInteger {
                    self.setupMembersListener(groupKey: intKey)
                }
                
            } catch {
                self.errorMessage = "Error loading user: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // Toggle chore completion using direct Firestore
    func toggleChoreCompletion(_ chore: CalendarChore) {
        guard let groupKey = groupKey else { return }
        
        // Use direct Firestore update since FirebaseInterface doesn't have this method
        FirebaseInterface.shared.firestore
            .collection("chores")
            .document("group")
            .collection(groupKey)
            .document(chore.id)
            .updateData(["completed": !chore.completed]) { error in
                if let error = error {
                    print("Error updating chore: \(error)")
                }
            }
    }
    
    // Delete a chore using direct Firestore
    func deleteChore(_ chore: CalendarChore) {
        guard let groupKey = groupKey else { return }
        
        // Use direct Firestore delete since FirebaseInterface doesn't have this method
        FirebaseInterface.shared.firestore
            .collection("chores")
            .document("group")
            .collection(groupKey)
            .document(chore.id)
            .delete { error in
                if let error = error {
                    print("Error deleting chore: \(error)")
                }
            }
    }
    
    // Private Methods
    
    // Set up real-time listener for chores using direct Firestore
    private func setupChoresListener(groupKey: String) {
        // Remove any existing listener
        choresListener?.remove()
        
        // Use direct Firestore listener since FirebaseInterface doesn't have listener methods
        choresListener = FirebaseInterface.shared.firestore
            .collection("chores")
            .document("group")
            .collection(groupKey)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    // ALWAYS set isLoading to false when we get a response
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = "Error loading chores: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        self.chores = []
                        return
                    }
                    
                    // Date formatter for parsing date strings
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    
                    // Convert Firestore documents to CalendarChore objects
                    self.chores = documents.compactMap { doc -> CalendarChore? in
                        let data = doc.data()
                        
                        guard let name = data["Name"] as? String else { return nil }
                        
                        let dateString = data["Date"] as? String ?? ""
                        let date = dateFormatter.date(from: dateString) ?? Date()
                        
                        return CalendarChore(
                            id: doc.documentID,
                            name: name,
                            description: data["Description"] as? String ?? "",
                            date: date,
                            dateString: dateString,
                            day: data["Day"] as? String ?? "",
                            priorityLevel: data["PriorityLevel"] as? String ?? "low",
                            repetitionTime: data["RepetitionTime"] as? String ?? "None",
                            timeLength: data["TimeLength"] as? Int ?? 0,
                            assignedUsers: data["assignedUsers"] as? [String] ?? [],
                            completed: data["completed"] as? Bool ?? false
                        )
                    }
                    
                    // Sort by date, then priority
                    self.chores.sort { chore1, chore2 in
                        if chore1.completed != chore2.completed {
                            return !chore1.completed
                        }
                        if chore1.date != chore2.date {
                            return chore1.date < chore2.date
                        }
                        return self.priorityRank(chore1.priorityLevel) < self.priorityRank(chore2.priorityLevel)
                    }
                    
                    print("Loaded \(self.chores.count) chores for calendar")
                }
            }
    }
    
    // Set up real-time listener for group members using direct Firestore
    private func setupMembersListener(groupKey: Int) {
        // Remove any existing listener
        membersListener?.remove()
        
        // Use direct Firestore listener since FirebaseInterface doesn't have listener methods
        membersListener = FirebaseInterface.shared.firestore
            .collection("Users")
            .whereField("groupKey", isEqualTo: groupKey)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error loading group members: \(error)")
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        self.groupMembers = []
                        return
                    }
                    
                    // Convert Firestore documents to GroupMemberInfo objects
                    self.groupMembers = documents.compactMap { doc -> GroupMemberInfo? in
                        let data = doc.data()
                        guard let name = data["Name"] as? String else { return nil }
                        
                        let colorString = data["color"] as? String ?? "Green"
                        let color = self.colorFromString(colorString)
                        
                        return GroupMemberInfo(
                            id: doc.documentID,
                            name: name,
                            color: color,
                            colorString: colorString
                        )
                    }
                    
                    print("Loaded \(self.groupMembers.count) group members")
                }
            }
    }
    
    // Convert color string to SwiftUI Color
    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red":
            return .red
        case "blue":
            return .blue
        case "green":
            return .green
        case "yellow":
            return .yellow
        case "orange":
            return .orange
        case "purple":
            return .purple
        case "pink":
            return .pink
        case "cyan":
            return .cyan
        case "mint":
            return .mint
        case "teal":
            return .teal
        case "indigo":
            return .indigo
        default:
            return .green
        }
    }
    
    // Priority ranking for sorting
    private func priorityRank(_ priority: String) -> Int {
        switch priority.lowercased() {
        case "high": return 0
        case "medium": return 1
        default: return 2
        }
    }
    
    // Used to prevent memory leaks from firebase
    // basically prevents firebase from listening to real time updates
    deinit {
        choresListener?.remove()
        membersListener?.remove()
    }
}
