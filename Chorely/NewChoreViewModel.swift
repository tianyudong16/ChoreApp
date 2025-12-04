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

// ViewModel for creating new chores
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
                
                // Fetch group members for assignment
                let members = try await fetchGroupMembers(groupKey: groupKeyInt)
                
                await MainActor.run {
                    self.groupKey = groupKeyStr
                    self.groupKeyInt = groupKeyInt
                    self.groupMemberCount = members.count
                    self.groupMembers = members
                    self.isLoading = false
                    print("GROUP KEY LOADED: \(groupKeyStr), MEMBERS: \(members.count)")
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
    
    // Convert color string to SwiftUI Color
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
        
        // Build assigned users array
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
            timeLength: timeLength, //saves user input
            assignedUsers: assignedUsers,
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
        selectedAssignee = nil
    }
}
