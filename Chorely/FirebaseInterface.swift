//
//  FirebaseInterface.swift
//  Chorely
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UIKit
import SwiftUI

class FirebaseInterface {
    
    static let shared = FirebaseInterface()
    private init() {}
    
    internal let db = Firestore.firestore()
    private let storage = Storage.storage()
}

// Sign Up
extension FirebaseInterface {
    
    //Creates a new FirebaseAuth account and user profile, then adds user to a group
    func signUp(
        name: String,
        email: String,
        password: String,
        groupName: String,
        groupPassword: String,
        completion: @escaping (Result<UserInfo, Error>) -> Void
    ) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error { return completion(.failure(error)) }
            guard let uid = authResult?.user.uid else { return }
            
            self.createOrJoinGroup(
                uid: uid,
                name: name,
                email: email,
                password: password,
                groupName: groupName,
                groupPassword: groupPassword,
                completion: completion
            )
        }
    }
}

// Creating/Joining a Group

extension FirebaseInterface {
    
    // Decide whether to join an existing group or create a new one
    private func createOrJoinGroup(
        uid: String,
        name: String,
        email: String,
        password: String,
        groupName: String,
        groupPassword: String,
        completion: @escaping (Result<UserInfo, Error>) -> Void
    ) {
        db.collection("groups")
            .whereField("name", isEqualTo: groupName)
            .getDocuments { snapshot, error in
                
                if let error = error { return completion(.failure(error)) }
                
                if let doc = snapshot?.documents.first {
                    // Group exists
                    let groupID = doc.documentID
                    let storedPassword = doc["password"] as? String ?? ""
                    
                    if storedPassword == groupPassword {
                        // Join existing
                        self.addUserToGroup(
                            uid: uid,
                            name: name,
                            email: email,
                            password: password,
                            groupID: groupID,
                            completion: completion
                        )
                    } else {
                        completion(.failure(
                            NSError(domain: "IncorrectGroupPassword", code: 0,
                                    userInfo: [NSLocalizedDescriptionKey: "Incorrect group password."])
                        ))
                    }
                } else {
                    // Create a new group
                    self.createGroupAndAddUser(
                        uid: uid,
                        name: name,
                        email: email,
                        password: password,
                        groupName: groupName,
                        groupPassword: groupPassword,
                        completion: completion
                    )
                }
            }
    }
    
    // Create a group document and then user
    private func createGroupAndAddUser(
        uid: String,
        name: String,
        email: String,
        password: String,
        groupName: String,
        groupPassword: String,
        completion: @escaping (Result<UserInfo, Error>) -> Void
    ) {
        let groupID = UUID().uuidString
        
        let data: [String: Any] = [
            "name": groupName,
            "password": groupPassword,
            "createdAt": Timestamp()
        ]
        
        db.collection("groups").document(groupID).setData(data) { err in
            if let err = err { return completion(.failure(err)) }
            
            self.addUserToGroup(
                uid: uid,
                name: name,
                email: email,
                password: password,
                groupID: groupID,
                completion: completion
            )
        }
    }
}

// Adding a user to a group

extension FirebaseInterface {
    
    private func addUserToGroup(
        uid: String,
        name: String,
        email: String,
        password: String,
        groupID: String,
        completion: @escaping (Result<UserInfo, Error>) -> Void
    ) {
        let defaultColor = UIColor.systemPink.cgColor
        let encodedColor = defaultColor.toData()!
        
        let userDoc: [String: Any] = [
            "uid": uid,
            "name": name,
            "email": email,
            "groupID": groupID,
            "photoURL": "",
            "colorData": encodedColor.base64EncodedString()
        ]
        
        // Save main profile
        db.collection("users").document(uid).setData(userDoc)
        
        // Save inside group collection
        db.collection("groups")
            .document(groupID)
            .collection("members")
            .document(uid)
            .setData(userDoc) { err in
                
                if let err = err { return completion(.failure(err)) }
                
                let user = UserInfo(
                    uid: uid,
                    name: name,
                    email: email,
                    groupID: groupID,
                    photoURL: "",
                    colorData: encodedColor
                )
                
                completion(.success(user))
            }
    }
}

// Login (with name and password)

extension FirebaseInterface {
    
    func loginWithName(
        name: String,
        password: String,
        completion: @escaping (Result<UserInfo, Error>) -> Void
    ) {
        //Step 1: Find the user by name
        db.collection("users")
            .whereField("name", isEqualTo: name)
            .getDocuments { snapshot, err in
                
                if let err = err { return completion(.failure(err)) }
                guard let doc = snapshot?.documents.first else {
                    return completion(.failure(
                        NSError(domain: "UserNotFound", code: 0,
                                userInfo: [NSLocalizedDescriptionKey: "No user with that name exists."])
                    ))
                }
                
                let email = doc["email"] as? String ?? ""
                
                //Step 2: Auth login using the inputted email & password
                Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                    if let error = error { return completion(.failure(error)) }
                    
                    do {
                        let user = try UserInfo(from: doc)
                        completion(.success(user))
                    } catch {
                        completion(.failure(error))
                    }
                }
            }
    }
}


// Getting user

extension FirebaseInterface {
    
    func fetchUser(uid: String, completion: @escaping (Result<UserInfo, Error>) -> Void) {
        db.collection("users").document(uid).getDocument { doc, err in
            if let err = err { return completion(.failure(err)) }
            if let doc = doc {
                do {
                    let user = try UserInfo(from: doc)
                    completion(.success(user))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
}


// Handling group members

extension FirebaseInterface {
    
    func listenToGroupMembers(
        groupID: String,
        onUpdate: @escaping ([GroupMember]) -> Void
    ) {
        db.collection("groups")
            .document(groupID)
            .collection("members")
            .addSnapshotListener { snapshot, err in
                
                guard let docs = snapshot?.documents else { return onUpdate([]) }
                
                let members = docs.compactMap { try? GroupMember(from: $0) }
                onUpdate(members)
            }
    }
}


// Updating profile through changes made in profile

extension FirebaseInterface {
    
    func updateUserName(uid: String, groupID: String, newName: String) {
        db.collection("users").document(uid).updateData(["name": newName])
        
        db.collection("groups")
            .document(groupID)
            .collection("members")
            .document(uid)
            .updateData(["name": newName])
    }
    
    func updateUserColor(uid: String, groupID: String, color: Color) {
        let cg = UIColor(color).cgColor
        let encoded = cg.toData()!.base64EncodedString()
        
        db.collection("users").document(uid).updateData(["colorData": encoded])
        
        db.collection("groups")
            .document(groupID)
            .collection("members")
            .document(uid)
            .updateData(["colorData": encoded])
    }
    
    func uploadUserPhoto(
        uid: String,
        groupID: String,
        image: UIImage,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let path = "profilePhotos/\(uid).jpg"
        let ref = storage.reference().child(path)
        
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        ref.putData(data, metadata: nil) { _, error in
            if let error = error { return completion(.failure(error)) }
            
            ref.downloadURL { url, error in
                if let error = error { return completion(.failure(error)) }
                guard let urlStr = url?.absoluteString else { return }
                
                self.db.collection("users").document(uid).updateData(["photoURL": urlStr])
                self.db.collection("groups")
                    .document(groupID)
                    .collection("members")
                    .document(uid)
                    .updateData(["photoURL": urlStr])
                
                completion(.success(urlStr))
            }
        }
    }
}

