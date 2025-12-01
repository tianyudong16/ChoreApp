//
//  NewChoreViewModel.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/25/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

// ViewModel for creating new chores
// Handles form state and saving to Firebase
class NewChoreViewModel: ObservableObject {
    
    // Form fields bound to the UI
    @Published var title = ""              // Chore name/title
    @Published var description = ""        // Optional description
    @Published var dueDate = Date()        // When the chore is due
    @Published var priorityLevel = "low"   // Priority: low/medium/high
    @Published var repetitionTime = "None" // Repeat: None/Daily/Weekly/Monthly/Yearly
    
    // UI state
    @Published var showAlert = false       // Shows error alert
    @Published var isLoading = true        // Shows loading state while fetching group
    
    // User's group key (needed to save chore to correct group)
    private var groupKey: String?
    
    init() {
        // Automatically fetch group key when ViewModel is created
        fetchGroupKey()
    }
    
    // Fetches the current user's group key from Firebase
    private func fetchGroupKey() {
        // Get current user's UID from Firebase Auth
        guard let uid = Auth.auth().currentUser?.uid else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.showAlert = true
            }
            return
        }
        
        Task {
            do {
                // Fetch user data using pre-existing function
                let userData = try await FirebaseInterface.shared.getUserData(uid: uid)
                
                // Extract group key using pre-existing helper
                let keys = FirebaseInterface.shared.extractGroupKey(from: userData)
                
                await MainActor.run {
                    self.groupKey = keys.string
                    self.isLoading = false
                    print("GROUP KEY LOADED: \(keys.string ?? "NIL")")
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.showAlert = true
                    print("Failed to load user data: \(error)")
                }
            }
        }
    }
    
    // Validates if the form can be saved
    // Requires: non-empty title, not loading, and valid group key
    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !isLoading &&
        groupKey != nil
    }
    
    // Saves the new chore to Firebase
    func save() {
        // Validate before saving
        guard canSave, let groupKey = groupKey else {
            showAlert = true
            return
        }
        
        // Format the due date as "yyyy-MM-dd" string
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: dueDate)
        
        // Get the day of week (e.g., "Monday")
        dateFormatter.dateFormat = "EEEE"
        let dayStr = dateFormatter.string(from: dueDate)
        
        // Create a new Chore object using the pre-existing struct
        let newChore = Chore(
            checklist: false,
            date: dateStr,
            day: dayStr,
            description: description,
            monthlyRepeatByDate: false,
            monthlyRepeatByWeek: "",
            name: title,
            priorityLevel: priorityLevel,
            repetitionTime: repetitionTime,
            timeLength: 30, // Default 30 minutes
            assignedUsers: [], // No assignees initially
            completed: false,
            votes: 0,
            voters: [],
            proposal: false
        )
        
        // Save using pre-existing addChore function
        addChore(chore: newChore, groupKey: groupKey)
        
        // Reset the form for next use
        resetForm()
    }
    
    // Clears the form fields
    private func resetForm() {
        title = ""
        description = ""
        dueDate = Date()
    }
}
