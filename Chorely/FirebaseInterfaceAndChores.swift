//
//  FirebaseInterfaceAndChores.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/13/25.
//
//  Extension for chore-related Firebase operations
//

import Foundation
import FirebaseFirestore

extension FirebaseInterface {
    
    // MARK: - SAVE CHORE
    func saveChore(chore: ChoreItem, groupID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let choreData: [String: Any] = [
            "id": chore.id.uuidString,
            "name": chore.name,
            "priority": chore.priority,
            "assignedTo": chore.assignedTo,
            "isCompleted": chore.isCompleted,
            "dueDate": chore.dueDate?.timeIntervalSince1970 ?? 0,
            "repetition": chore.repetition,
            "estimatedTime": chore.estimatedTime,
            "description": chore.description,
            "isPending": chore.isPending,
            "proposedBy": chore.proposedBy,
            "createdAt": Timestamp()
        ]
        
        db.collection("groups")
            .document(groupID)
            .collection("chores")
            .document(chore.id.uuidString)
            .setData(choreData) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    
    // MARK: - FETCH CHORES
    func fetchChores(groupID: String, completion: @escaping (Result<[ChoreItem], Error>) -> Void) {
        db.collection("groups")
            .document(groupID)
            .collection("chores")
            .getDocuments { snapshot, error in
                
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let chores = documents.compactMap { doc -> ChoreItem? in
                    let data = doc.data()
                    
                    guard let idString = data["id"] as? String,
                          let id = UUID(uuidString: idString),
                          let name = data["name"] as? String else {
                        return nil
                    }
                    
                    let priority = data["priority"] as? Int ?? 2
                    let assignedTo = data["assignedTo"] as? String ?? ""
                    let isCompleted = data["isCompleted"] as? Bool ?? false
                    let dueDateInterval = data["dueDate"] as? TimeInterval ?? 0
                    let dueDate = dueDateInterval > 0 ? Date(timeIntervalSince1970: dueDateInterval) : nil
                    let repetition = data["repetition"] as? String ?? "none"
                    let estimatedTime = data["estimatedTime"] as? Int ?? 30
                    let description = data["description"] as? String ?? ""
                    let isPending = data["isPending"] as? Bool ?? false
                    let proposedBy = data["proposedBy"] as? String ?? ""
                    
                    return ChoreItem(
                        id: id,
                        name: name,
                        priority: priority,
                        assignedTo: assignedTo,
                        isCompleted: isCompleted,
                        dueDate: dueDate,
                        repetition: repetition,
                        estimatedTime: estimatedTime,
                        description: description,
                        isPending: isPending,
                        proposedBy: proposedBy
                    )
                }
                
                completion(.success(chores))
            }
    }
    
    // MARK: - UPDATE CHORE COMPLETION
    func updateChoreCompletion(choreID: String, groupID: String, isCompleted: Bool) {
        db.collection("groups")
            .document(groupID)
            .collection("chores")
            .document(choreID)
            .updateData(["isCompleted": isCompleted])
    }
    
    // MARK: - DELETE CHORE
    func deleteChore(choreID: String, groupID: String) {
        db.collection("groups")
            .document(groupID)
            .collection("chores")
            .document(choreID)
            .delete()
    }
    
    // MARK: - LISTEN TO CHORES (Real-time updates)
    func listenToChores(groupID: String, onUpdate: @escaping ([ChoreItem]) -> Void) {
        db.collection("groups")
            .document(groupID)
            .collection("chores")
            .addSnapshotListener { snapshot, error in
                
                guard let documents = snapshot?.documents else {
                    onUpdate([])
                    return
                }
                
                let chores = documents.compactMap { doc -> ChoreItem? in
                    let data = doc.data()
                    
                    guard let idString = data["id"] as? String,
                          let id = UUID(uuidString: idString),
                          let name = data["name"] as? String else {
                        return nil
                    }
                    
                    let priority = data["priority"] as? Int ?? 2
                    let assignedTo = data["assignedTo"] as? String ?? ""
                    let isCompleted = data["isCompleted"] as? Bool ?? false
                    let dueDateInterval = data["dueDate"] as? TimeInterval ?? 0
                    let dueDate = dueDateInterval > 0 ? Date(timeIntervalSince1970: dueDateInterval) : nil
                    let repetition = data["repetition"] as? String ?? "none"
                    let estimatedTime = data["estimatedTime"] as? Int ?? 30
                    let description = data["description"] as? String ?? ""
                    let isPending = data["isPending"] as? Bool ?? false
                    let proposedBy = data["proposedBy"] as? String ?? ""
                    
                    return ChoreItem(
                        id: id,
                        name: name,
                        priority: priority,
                        assignedTo: assignedTo,
                        isCompleted: isCompleted,
                        dueDate: dueDate,
                        repetition: repetition,
                        estimatedTime: estimatedTime,
                        description: description,
                        isPending: isPending,
                        proposedBy: proposedBy
                    )
                }
                
                onUpdate(chores)
            }
    }
    
    // MARK: - APPROVE CHORE
    func approveChore(choreID: String, groupID: String) {
        db.collection("groups")
            .document(groupID)
            .collection("chores")
            .document(choreID)
            .updateData(["isPending": false])
    }
    
    // MARK: - DENY/REJECT CHORE
    func denyChore(choreID: String, groupID: String) {
        db.collection("groups")
            .document(groupID)
            .collection("chores")
            .document(choreID)
            .delete()
    }
}
