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
    
    // User and group info
    private var groupKey: String?
    private var groupKeyInt: Int?
    private var currentUserID: String?
    private var groupMemberCount: Int = 0
    
    init() {
        fetchGroupKey()
    }
    
    // Fetches the current user's group key and counts group members
    private func fetchGroupKey() {
        guard let uid = Auth.auth().currentUser?.uid else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.showAlert = true
            }
            return
        }
        
        self.currentUserID = uid
        
        Task {
            do {
                // Fetch user data
                let userData = try await FirebaseInterface.shared.getUserData(uid: uid)
                let keys = FirebaseInterface.shared.extractGroupKey(from: userData)
                
                guard let groupKeyStr = keys.string, let groupKeyInt = keys.int else {
                    await MainActor.run {
                        self.isLoading = false
                        self.showAlert = true
                    }
                    return
                }
                
                // Count how many members are in this group
                let memberCount = try await countGroupMembers(groupKey: groupKeyInt)
                
                await MainActor.run {
                    self.groupKey = groupKeyStr
                    self.groupKeyInt = groupKeyInt
                    self.groupMemberCount = memberCount
                    self.isLoading = false
                    print("GROUP KEY LOADED: \(groupKeyStr), MEMBERS: \(memberCount)")
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
    
    // Counts how many users are in the group
    private func countGroupMembers(groupKey: Int) async throws -> Int {
        let snapshot = try await FirebaseInterface.shared.firestore
            .collection("Users")
            .whereField("groupKey", isEqualTo: groupKey)
            .getDocuments()
        
        return snapshot.documents.count
    }
    
    // Validates if the form can be saved
    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !isLoading &&
        groupKey != nil
    }
    
    // Saves the new chore to Firebase
    func save() {
        guard canSave,
              let groupKey = groupKey,
              let userID = currentUserID else {
            showAlert = true
            return
        }
        
        // Format the due date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: dueDate)
        
        dateFormatter.dateFormat = "EEEE"
        let dayStr = dateFormatter.string(from: dueDate)
        
        // If only 1 user in group, auto-approve (proposal = false)
        // Otherwise, set as pending (proposal = true)
        let needsApproval = groupMemberCount > 1
        
        // Generate a unique series ID for repeating chores
        let seriesId = repetitionTime != "None" ? UUID().uuidString : ""
        
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
            timeLength: 30,
            assignedUsers: [],
            completed: false,
            voters: [],
            proposal: needsApproval,
            createdBy: userID,
            seriesId: seriesId
        )
        
        // Add the first chore
        addChore(chore: newChore, groupKey: groupKey)
        
        // If it's a repeating chore and auto-approved, generate future occurrences
        // For pending chores, repetitions will be generated after approval
        if !needsApproval && repetitionTime != "None" {
            FirebaseInterface.shared.generateRepetitions(for: newChore, groupKey: groupKey, seriesId: seriesId)
        }
        
        resetForm()
    }
    
    private func resetForm() {
        title = ""
        description = ""
        dueDate = Date()
    }
}
