//
//  NewChoreViewModel.swift
//  Chorely
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class NewChoreViewModel: ObservableObject {
    // MARK: - Form Fields
    @Published var title = ""
    @Published var description = ""
    @Published var dueDate = Date()
    @Published var priorityLevel = "low"
    @Published var repetitionTime = "None"
    
    // MARK: - UI State
    @Published var showAlert = false
    @Published var isLoading = true          // ← Shows "Loading your group..."
    
    // MARK: - Private
    private var groupKey: String?
    
    init() {
        fetchGroupKey()
    }
    
    // MARK: - Fetch Group Key (only once)
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
                
                // TRY ALL POSSIBLE WAYS groupKey is stored
                var key: String?
                
                if let intKey = userData["groupKey"] as? Int {
                    key = String(intKey)
                } else if let intKey = userData["GroupKey"] as? Int {
                    key = String(intKey)
                } else if let strKey = userData["groupKey"] as? String {
                    key = strKey
                } else if let strKey = userData["GroupKey"] as? String {
                    key = strKey
                }
                
                await MainActor.run {
                    self.groupKey = key
                    self.isLoading = false
                    print("FINAL GROUP KEY LOADED: \(key ?? "NIL")")
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
    
    // MARK: - Can Save?
    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !isLoading &&
        groupKey != nil
    }
    
    // MARK: - Save Chore (Actually Works!)
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
        
        let choreData: [String: Any] = [
            "Checklist": false,
            "Date": dateStr,
            "Day": dayStr,
            "Description": description,
            "MonthlyRepeatByDate": false,
            "MonthlyRepeatByWeek": "",
            "Name": title,
            "PriorityLevel": priorityLevel,
            "RepetitionTime": repetitionTime,
            "TimeLength": 30,
            "assignedUsers": [],
            "completed": false
        ]
        
        FirebaseInterface.shared.firestore
            .collection("chores")
            .document("group")
            .collection(groupKey)
            .addDocument(data: choreData) { error in
                if let error = error {
                    print("Save failed: \(error)")
                } else {
                    print("Chore saved successfully!")
                    // Reset form
                    DispatchQueue.main.async {
                        self.title = ""
                        self.description = ""
                        self.dueDate = Date()
                    }
                }
            }
    }
}
