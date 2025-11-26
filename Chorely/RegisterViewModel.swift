//
//  RegisterViewModel.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/17/25.
//

import Foundation

@MainActor
class RegisterViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var groupName = ""
    @Published var errorMessage = ""
    
    // Generate a unique 6-digit group key
    private func generateUniqueGroupKey() -> Int {
        return Int.random(in: 100000...999999)
    }
    
    // Milo's exact createUser function
    func createUser(name: String, email: String, groupName: String, password: String, groupKey: Int? = nil, completion: @escaping (Bool, UserInfo?) -> Void) {
        guard !name.isEmpty, !groupName.isEmpty else {
            errorMessage = "No name or groupName found!"
            print("no name or groupName found!")
            completion(false, nil)
            return
        }
        guard !password.isEmpty else {
            errorMessage = "No password found!"
            print("no password found!")
            completion(false, nil)
            return
        }
        guard !email.isEmpty else {
            errorMessage = "No email found!"
            print("no email found!")
            completion(false, nil)
            return
        }
        
        Task {
            do {
                let returnedUserData = try await FirebaseInterface.shared.addUser(
                    name: name,
                    email: email,
                    groupKey: groupKey,
                    groupName: groupName,
                    password: password
                )
                print("success")
                print("Created user with groupKey: \(groupKey ?? 0) and groupName: \(groupName)")
                
                let userInfo = UserInfo(
                    uid: returnedUserData.uid,
                    name: name,
                    groupName: groupName,
                    email: email
                )
                
                completion(true, userInfo)
                
            } catch {
                print("Error: \(error)")
                errorMessage = "Registration failed: \(error.localizedDescription)"
                completion(false, nil)
            }
        }
    }
    
    func register(completion: @escaping (UserInfo?) -> Void) {
        let groupKey = generateUniqueGroupKey()
        UserDefaults.standard.set(groupKey, forKey: "lastGeneratedGroupCode")

        createUser(name: name, email: email, groupName: groupName, password: password, groupKey: groupKey) { success, userInfo in
            completion(userInfo)
        }
    }
    
    // FIXED: Use the joinGroup function to properly add user to group
    func registerWithGroupCode(groupCode: String, completion: @escaping (UserInfo?) -> Void) {
        guard !groupCode.isEmpty else {
            errorMessage = "Please enter a group code"
            completion(nil)
            return
        }
        
        guard let groupKeyInt = Int(groupCode) else {
            errorMessage = "Group code must be a 6-digit number"
            completion(nil)
            return
        }
        
        Task {
            do {
                print("DEBUG: Searching for groupKey: \(groupKeyInt) (type: Int)")
                
                // First try searching with Int type
                var snapshot = try await FirebaseInterface.shared.firestore
                    .collection("Users")
                    .whereField("groupKey", isEqualTo: groupKeyInt)
                    .limit(to: 1)
                    .getDocuments()
                
                // If not found as Int, try as String (in case of data inconsistency)
                if snapshot.documents.isEmpty {
                    print("DEBUG: Not found as Int, trying as String...")
                    snapshot = try await FirebaseInterface.shared.firestore
                        .collection("Users")
                        .whereField("groupKey", isEqualTo: groupCode)
                        .limit(to: 1)
                        .getDocuments()
                }
                
                print("DEBUG: Found \(snapshot.documents.count) documents")
                
                guard !snapshot.documents.isEmpty else {
                    await MainActor.run {
                        self.errorMessage = "Invalid group code. No group found with code: \(groupCode)"
                    }
                    completion(nil)
                    return
                }
                
                let existingUserData = snapshot.documents[0].data()
                print("DEBUG: Found user data: \(existingUserData)")
                
                let actualGroupName = existingUserData["groupName"] as? String ?? "Home Group"
                
                // Now create the new user with the SAME groupKey (as Int)
                let returnedUserData = try await FirebaseInterface.shared.addUser(
                    name: self.name,
                    email: self.email,
                    groupKey: groupKeyInt,
                    groupName: actualGroupName,
                    password: self.password
                )
                
                let userInfo = UserInfo(
                    uid: returnedUserData.uid,
                    name: self.name,
                    groupName: actualGroupName,
                    email: self.email
                )
                
                print("Successfully joined group: \(actualGroupName) (code: \(groupCode))")
                completion(userInfo)
                
            } catch {
                print("Error joining group: \(error)")
                await MainActor.run {
                    self.errorMessage = "Failed to join group: \(error.localizedDescription)"
                }
                completion(nil)
            }
        }
    }
}
