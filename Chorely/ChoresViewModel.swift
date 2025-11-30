//
//  ChoresViewModel.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/25/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class ChoresViewModel: ObservableObject {
    
    @Published var showingNewChoreView = false
    @Published var chores: [String: Chore] = [:]
    @Published var isLoading = true
    @Published var errorMessage = ""
    
    private var groupKey: String?
    private var groupKeyInt: Int?
    private var currentUserName: String = ""
    private var listener: ListenerRegistration?
    
    init() {}
    
    // sorts the chores based on ID
    // earlier date gets priority, and then completed chores is at the bottom of the list
    var sortedChoreIDs: [String] {
        chores.keys.sorted { id1, id2 in
            guard let chore1 = chores[id1], let chore2 = chores[id2] else { return false }
            
            if chore1.completed != chore2.completed {
                return !chore1.completed // returns uncompleted chore
            }
            if chore1.date != chore2.date {
                return chore1.date < chore2.date // checks date
            }
            return priorityRank(chore1.priorityLevel) < priorityRank(chore2.priorityLevel)
        }
    }
    
    func loadChores(userID: String) {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let userData = try await FirebaseInterface.shared.getUserData(uid: userID)
                let keys = FirebaseInterface.shared.extractGroupKey(from: userData)
                
                self.currentUserName = userData["Name"] as? String ?? "User"
                
                guard let key = keys.string else {
                    self.errorMessage = "No group key found"
                    self.isLoading = false
                    return
                }
                
                self.groupKey = key
                self.groupKeyInt = keys.int
                self.setupChoresListener(groupKey: key)
                
            } catch {
                self.errorMessage = "Error loading user: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func toggleChoreCompletion(choreID: String) {
        guard let groupKey = groupKey,
              let groupKeyInt = groupKeyInt,
              let chore = chores[choreID] else { return }
        
        if chore.completed {
            editChore( // calls editChore function from FirebaseInterface
                documentId: choreID,
                checklist: chore.checklist,
                date: chore.date,
                day: chore.day,
                description: chore.description,
                monthlyrepeatbydate: chore.monthlyRepeatByDate,
                monthlyrepeatbyweek: chore.monthlyRepeatByWeek,
                Name: chore.name,
                PriorityLevel: chore.priorityLevel,
                RepetitionTime: chore.repetitionTime,
                TimeLength: chore.timeLength,
                assignedUsers: chore.assignedUsers,
                completed: false,
                groupKey: groupKeyInt
            ) { success in
                if success {
                    print("Chore unchecked successfully")
                }
            }
        } else {
            FirebaseInterface.shared.markComplete(
                userName: currentUserName,
                choreId: choreID,
                groupKey: groupKey
            )
        }
    }
    
    func deleteChore(choreID: String) {
        guard let groupKey = groupKey else { return }
        FirebaseInterface.shared.deleteChore(groupKey: groupKey, choreId: choreID)
    }
    
    private func setupChoresListener(groupKey: String) {
        listener?.remove()
        
        listener = FirebaseInterface.shared.addChoresListener(groupKey: groupKey) { [weak self] documents, error in
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
                
                self.chores = self.readChoreDocuments(documents)
                print("Loaded \(self.chores.count) chores")
            }
        }
    }
    
    private func readChoreDocuments(_ documents: [QueryDocumentSnapshot]) -> [String: Chore] {
        var result: [String: Chore] = [:]
        
        for doc in documents {
            let data = doc.data()
            guard let name = data["Name"] as? String else { continue }
            
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
                completed: data["completed"] as? Bool ?? false
            )
            result[doc.documentID] = chore
        }
        
        return result
    }
    
    private func priorityRank(_ priority: String) -> Int {
        switch priority.lowercased() {
        case "high": return 0
        case "medium": return 1
        default: return 2
        }
    }
    
    deinit {
        listener?.remove()
    }
}
