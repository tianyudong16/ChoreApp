//
//  NewChoreViewModel.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/25/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

// Represents a group member for assignment picker
struct AssignableMember: Identifiable {
    let id: String
    let name: String
    let color: Color
}

// ViewModel for creating and editing chores
// Handles form state and saving to Firebase
class NewChoreViewModel: ObservableObject {
    
    // Form fields bound to the UI
    @Published var title = ""              // Chore name/title
    @Published var description = ""        // Optional description
    @Published var dueDate = Date()        // When the chore is due
    @Published var priorityLevel = "low"   // Priority: low/medium/high
    @Published var repetitionTime = "None" // Repeat: None/Daily/Weekly/Monthly/Yearly
    @Published var selectedAssignee: String? = nil // Selected user to assign chore to
    @Published var timeLength: Int = 30 //chore duration
    
    // Group members for assignment picker
    @Published var groupMembers: [AssignableMember] = []
    
    // UI state
    @Published var showAlert = false
    @Published var isLoading = true
    
    // Edit mode properties
    private var isEditMode = false
    private var editingChoreID: String?
    private var originalChore: Chore?
    
    // User and group info
    private var groupKey: String?
    private var groupKeyInt: Int?
    private var currentUserID: String?
    private var currentUserName: String?
    private var groupMemberCount: Int = 0
    
    // Check if we're in edit mode
    var isEditing: Bool {
        return isEditMode
    }
    
    init() {
        fetchGroupKey()
    }
    
    // Configure the view model for editing an existing chore
    func configureForEditing(choreID: String, chore: Chore) {
        isEditMode = true
        editingChoreID = choreID
        originalChore = chore
        
        // Pre-fill form fields with existing chore data
        title = chore.name
        description = chore.description
        priorityLevel = chore.priorityLevel
        repetitionTime = chore.repetitionTime
        timeLength = chore.timeLength
        selectedAssignee = chore.assignedUsers.first
        
        // Parse the date string back to Date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let parsedDate = formatter.date(from: chore.date) {
            dueDate = parsedDate
        }
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
                let userData = try await FirebaseInterface.shared.getUserData(uid: uid)
                let keys = FirebaseInterface.shared.extractGroupKey(from: userData)
                
                // Get the current user's name for approval logic
                let userName = userData["Name"] as? String
                
                guard let groupKeyStr = keys.string, let groupKeyInt = keys.int else {
                    await MainActor.run {
                        self.isLoading = false
                        self.showAlert = true
                    }
                    return
                }
                
                let members = try await fetchGroupMembers(groupKey: groupKeyInt)
                
                await MainActor.run {
                    self.groupKey = groupKeyStr
                    self.groupKeyInt = groupKeyInt
                    self.groupMemberCount = members.count
                    self.groupMembers = members
                    self.currentUserName = userName
                    self.isLoading = false
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
    
    // Fetches all group members with their names and colors
    private func fetchGroupMembers(groupKey: Int) async throws -> [AssignableMember] {
        let snapshot = try await FirebaseInterface.shared.firestore
            .collection("Users")
            .whereField("groupKey", isEqualTo: groupKey)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc -> AssignableMember? in
            let data = doc.data()
            guard let name = data["Name"] as? String else { return nil }
            
            let colorString = data["color"] as? String ?? "Green"
            let color = colorFromString(colorString)
            
            return AssignableMember(id: doc.documentID, name: name, color: color)
        }
    }
    
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
    
    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !isLoading &&
        groupKey != nil
    }
    
    // Saves or updates the chore depending on mode
    func save() {
        if isEditMode {
            updateChore()
        } else {
            createNewChore()
        }
    }
    
    // Updates an existing chore
    private func updateChore() {
        guard canSave,
              let groupKey = groupKey,
              let choreID = editingChoreID,
              let original = originalChore else {
            showAlert = true
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: dueDate)
        
        dateFormatter.dateFormat = "EEEE"
        let dayStr = dateFormatter.string(from: dueDate)
        
        var assignedUsers: [String] = []
        if let assignee = selectedAssignee {
            assignedUsers = [assignee]
        }
        
        let updatedChore = Chore(
            checklist: original.checklist,
            date: dateStr,
            day: dayStr,
            description: description,
            monthlyRepeatByDate: original.monthlyRepeatByDate,
            monthlyRepeatByWeek: original.monthlyRepeatByWeek,
            name: title,
            priorityLevel: priorityLevel,
            repetitionTime: repetitionTime,
            timeLength: timeLength,
            assignedUsers: assignedUsers,
            completed: original.completed,
            voters: original.voters,
            proposal: original.proposal,
            createdBy: original.createdBy,
            seriesId: original.seriesId
        )
        
        editChore(documentId: choreID, chore: updatedChore, groupKey: groupKey) { success in
            if !success {
                print("Failed to update chore")
            }
        }
    }
    
    // Creates a new chore
    private func createNewChore() {
        guard canSave,
              let groupKey = groupKey,
              let userID = currentUserID else {
            showAlert = true
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: dueDate)
        
        dateFormatter.dateFormat = "EEEE"
        let dayStr = dateFormatter.string(from: dueDate)
        
        // Check if the chore is assigned to the current user
        let isAssignedToSelf = selectedAssignee != nil && selectedAssignee == currentUserName
        
        // Skip approval if: only 1 user in group OR chore is assigned to self
        let needsApproval = groupMemberCount > 1 && !isAssignedToSelf
        
        let seriesId = repetitionTime != "None" ? UUID().uuidString : ""
        
        var assignedUsers: [String] = []
        if let assignee = selectedAssignee {
            assignedUsers = [assignee]
        }
        
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
            timeLength: timeLength,
            assignedUsers: assignedUsers,
            completed: false,
            voters: [],
            proposal: needsApproval,
            createdBy: userID,
            seriesId: seriesId
        )
        
        addChore(chore: newChore, groupKey: groupKey)
        
        // Generate repetitions if chore doesn't need approval and is repeating
        if !needsApproval && repetitionTime != "None" {
            FirebaseInterface.shared.generateRepetitions(for: newChore, groupKey: groupKey, seriesId: seriesId)
        }
        
        resetForm()
    }
    
    private func resetForm() {
        title = ""
        description = ""
        dueDate = Date()
        selectedAssignee = nil
        priorityLevel = "low"
        repetitionTime = "None"
        timeLength = 30
    }
}
