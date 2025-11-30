//
//  NewChoreViewModel.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/25/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class NewChoreViewModel: ObservableObject {
    @Published var title = ""
    @Published var description = ""
    @Published var dueDate = Date()
    @Published var priorityLevel = "low"
    @Published var repetitionTime = "None"
    
    @Published var showAlert = false
    @Published var isLoading = true
    
    private var groupKey: String?
    
    init() {
        fetchGroupKey()
    }
    
    private func fetchGroupKey() {
        guard let uid = Auth.auth().currentUser?.uid else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.showAlert = true
            }
            return
        }
        
        Task {
            do {
                let userData = try await FirebaseInterface.shared.getUserData(uid: uid)
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
    
    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !isLoading &&
        groupKey != nil
    }
    
    func save() {
        guard canSave, let groupKey = groupKey else {
            showAlert = true
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: dueDate)
        
        dateFormatter.dateFormat = "EEEE"
        let dayStr = dateFormatter.string(from: dueDate)
        
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
            completed: false
        )
        
        addChore(chore: newChore, groupKey: groupKey)
        resetForm()
    }
    
    private func resetForm() {
        title = ""
        description = ""
        dueDate = Date()
    }
}
