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
    @Published var approvedChores: [(id: String, chore: Chore)] = []
    @Published var pendingChores:  [(id: String, chore: Chore)] = []
    
    private var groupKey: String?
    private var groupKeyInt: Int?
    private var currentUserName: String = ""
    private var listener: ListenerRegistration?
    
    init() {}
    
    func startListening(groupKey: String) {
            self.groupKey = groupKey
            self.groupKeyInt = Int(groupKey)
            setupChoresListener(groupKey: groupKey)
        }
    
    var sortedChoreIDs: [String] {
        chores.keys.sorted { id1, id2 in
            guard let chore1 = chores[id1], let chore2 = chores[id2] else { return false }
            
            if chore1.completed != chore2.completed {
                return !chore1.completed
            }
            if chore1.date != chore2.date {
                return chore1.date < chore2.date
            }
            return priorityRank(chore1.priorityLevel) < priorityRank(chore2.priorityLevel)
        }
    }
    
    func fetchUserAndLoadChores(userID: String) {
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
              let chore = chores[choreID] else { return }
        
        if chore.completed {
            // Create a Chore object for editing
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
                voters: chore.voters,
                proposal: chore.proposal
            )
            
            editChore(documentId: choreID, chore: updatedChore, groupKey: groupKey) { success in
                if success {
                    print("Chore unchecked successfully")
                }
            }
        } else {
            Task {
                await FirebaseInterface.shared.markComplete(
                    userName: currentUserName,
                    choreId: choreID,
                    groupKey: groupKey
                )
            }
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
                    self.pendingChores = []
                    self.approvedChores = []
                    return
                }
                
                self.chores = self.readChoreDocuments(documents)
                let choreList = self.chores.map { (id: $0.key, chore: $0.value) }
                self.updateChoreLists(choreList)
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
                completed: data["completed"] as? Bool ?? false,
                voters: data["voters"] as? [String] ?? [],
                proposal: data["proposal"] as? Bool ?? false,
                createdBy: data["createdBy"] as? String ?? ""
            )
            result[doc.documentID] = chore
        }
        
        return result
    }
    
    func updateChoreLists(_ choreList: [(id: String, chore: Chore)]) {
        // Filter into approved and pending
        let approved = choreList.filter { !$0.chore.proposal }
        let pending = choreList.filter { $0.chore.proposal }
        
        // Sort approved chores: uncompleted first, then by date, then by priority
        self.approvedChores = approved.sorted { item1, item2 in
            let chore1 = item1.chore
            let chore2 = item2.chore
            
            if chore1.completed != chore2.completed {
                return !chore1.completed
            }
            if chore1.date != chore2.date {
                return chore1.date < chore2.date
            }
            return priorityRank(chore1.priorityLevel) < priorityRank(chore2.priorityLevel)
        }
        
        self.pendingChores = pending
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
