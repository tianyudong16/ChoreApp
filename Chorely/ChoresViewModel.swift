//
//  ChoresViewModel.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/25/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - ChoreListItem Model
/// Model for displaying a chore in the chores list
/// Named "ChoreListItem" to avoid conflict with other ChoreItem definitions in the project
struct ChoreListItem: Identifiable {
    let id: String // Firebase document ID
    let name: String // Chore name/title
    let description: String // Optional description
    let date: String // Due date as string (e.g., "2025-01-15")
    let day: String // Day of week (e.g., "Monday")
    let priorityLevel: String // "low", "medium", or "high"
    let repetitionTime: String // "None", "Daily", "Weekly", etc.
    let timeLength: Int // Estimated time in minutes
    let assignedUsers: [String] // Array of user IDs assigned to this chore
    var completed: Bool // Whether the chore is completed
    
    /// Returns the color name based on priority level
    var priorityColor: String {
        switch priorityLevel.lowercased() {
        case "high":
            return "red"
        case "medium":
            return "orange"
        default:
            return "green"
        }
    }
}

// MARK: - ChoresViewModel
/// ViewModel for the list of chores view
/// Handles fetching, displaying, and managing chores from Firebase
/// Primary location for chores when "View Chores" button is clicked on the home page
@MainActor
class ChoresViewModel: ObservableObject {
    
    // MARK: - Published Properties (UI State)
    @Published var showingNewChoreView = false // Controls the new chore sheet
    @Published var chores: [ChoreListItem] = [] // Array of chores to display
    @Published var isLoading = true // Shows loading spinner
    @Published var errorMessage = "" // Error message to display
    
    // MARK: - Private Properties
    private var groupKey: String? // User's group key for fetching chores
    private var listener: ListenerRegistration? // Firestore real-time listener
    
    init() {}
    
    // MARK: - Public Methods
    
    /// Fetches the user's groupKey from Firebase, then loads their group's chores
    /// - Parameter userID: The Firebase Auth UID of the current user
    func loadChores(userID: String) {
        isLoading = true
        errorMessage = ""
        
        // Step 1: Get the user's document to find their groupKey
        FirebaseInterface.shared.firestore
            .collection("Users")
            .document(userID)
            .getDocument { [weak self] snapshot, error in
                guard let self = self else { return }
                
                // Handle errors fetching user document
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = "Error loading user: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                    return
                }
                
                // Make sure user data exists
                guard let data = snapshot?.data() else {
                    DispatchQueue.main.async {
                        self.errorMessage = "User data not found"
                        self.isLoading = false
                    }
                    return
                }
                
                // Extract groupKey - it could be stored as Int or String in Firebase
                var groupKeyString: String?
                if let intKey = data["groupKey"] as? Int {
                    groupKeyString = String(intKey)
                } else if let strKey = data["groupKey"] as? String {
                    groupKeyString = strKey
                }
                
                // Make sure we found a groupKey
                guard let key = groupKeyString else {
                    DispatchQueue.main.async {
                        self.errorMessage = "No group key found"
                        self.isLoading = false
                    }
                    return
                }
                
                // Step 2: Now set up the chores listener with the groupKey
                DispatchQueue.main.async {
                    self.groupKey = key
                    self.setupChoresListener(groupKey: key)
                }
            }
    }
    
    /// Toggles a chore's completion status in Firebase
    /// chore parameter toggles the chore to be completed
    func toggleChoreCompletion(_ chore: ChoreListItem) {
        guard let groupKey = groupKey else { return }
        
        // Update the 'completed' field to the opposite value
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
    
    /// Deletes a chore from Firebase
    /// - Parameter chore: The chore to delete
    func deleteChore(_ chore: ChoreListItem) {
        guard let groupKey = groupKey else { return }
        
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
    
    // MARK: - Private Methods
    
    /// Sets up a real-time Firestore listener for the group's chores
    /// This means the UI will automatically update when chores are added/changed/deleted
    /// - Parameter groupKey: The group's key to fetch chores for
    private func setupChoresListener(groupKey: String) {
        // Remove any existing listener to avoid duplicates
        listener?.remove()
        
        // Set up listener on the chores/group/{groupKey} collection
        listener = FirebaseInterface.shared.firestore
            .collection("chores")
            .document("group")
            .collection(groupKey)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    // Handle any errors
                    if let error = error {
                        self.errorMessage = "Error loading chores: \(error.localizedDescription)"
                        return
                    }
                    
                    // If no documents, set empty array
                    guard let documents = querySnapshot?.documents else {
                        self.chores = []
                        return
                    }
                    
                    // Convert Firestore documents to ChoreListItem objects
                    // compactMap filters out any nil values (documents that fail to parse)
                    self.chores = documents.compactMap { doc -> ChoreListItem? in
                        let data = doc.data()
                        
                        // Name is required - skip documents without it
                        guard let name = data["Name"] as? String else { return nil }
                        
                        return ChoreListItem(
                            id: doc.documentID,
                            name: name,
                            description: data["Description"] as? String ?? "",
                            date: data["Date"] as? String ?? "",
                            day: data["Day"] as? String ?? "",
                            priorityLevel: data["PriorityLevel"] as? String ?? "low",
                            repetitionTime: data["RepetitionTime"] as? String ?? "None",
                            timeLength: data["TimeLength"] as? Int ?? 0,
                            assignedUsers: data["assignedUsers"] as? [String] ?? [],
                            completed: data["completed"] as? Bool ?? false
                        )
                    }
                    
                    // Sort chores: uncompleted first, then by date, then by priority
                    self.chores.sort { chore1, chore2 in
                        // Completed chores go to the bottom
                        if chore1.completed != chore2.completed {
                            return !chore1.completed
                        }
                        // Sort by date (earlier dates first)
                        if chore1.date != chore2.date {
                            return chore1.date < chore2.date
                        }
                        // Sort by priority (high > medium > low)
                        let priority1 = self.priorityRank(chore1.priorityLevel)
                        let priority2 = self.priorityRank(chore2.priorityLevel)
                        return priority1 < priority2
                    }
                    
                    print("Loaded \(self.chores.count) chores")
                }
            }
    }
    
    /// Converts priority string to a numeric rank for sorting
    /// Lower number = higher priority
    private func priorityRank(_ priority: String) -> Int {
        switch priority.lowercased() {
        case "high": return 0
        case "medium": return 1
        default: return 2
        }
    }
    
    // MARK: - Cleanup
    
    /// Called when the ViewModel is deallocated
    /// Removes the Firestore listener to prevent memory leaks
    deinit {
        listener?.remove()
    }
}
