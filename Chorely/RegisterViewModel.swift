//
//  RegisterViewModel.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/17/25.
//

import Foundation

// ViewModel for handling user registration
// Supports both creating new groups and joining existing ones
@MainActor
class RegisterViewModel: ObservableObject {
    
    // Form fields bound to the UI
    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var groupName = ""
    @Published var errorMessage = ""
    
    // Generates a random 6-digit group key
    private func generateUniqueGroupKey() -> Int {
        return Int.random(in: 100000...999999)
    }
    
    // Creates a new user account with the provided information
    // Used internally by register() and registerWithGroupCode()
    func createUser(name: String, email: String, groupName: String, password: String, groupKey: Int? = nil, completion: @escaping (Bool, UserInfo?) -> Void) {
        // Validate required fields
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
                // Use pre-existing addUser function from FirebaseInterface
                let returnedUserData = try await FirebaseInterface.shared.addUser(
                    name: name,
                    email: email,
                    groupKey: groupKey,
                    groupName: groupName,
                    password: password
                )
                print("success")
                print("Created user with groupKey: \(groupKey ?? 0) and groupName: \(groupName)")
                
                // Create UserInfo to return to the view
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
    
    // Registers a new user and creates a new group
    // Generates a random 6-digit group code
    func register(completion: @escaping (UserInfo?) -> Void) {
        // Generate new group key
        let groupKey = generateUniqueGroupKey()
        
        // Store for display in success alert
        UserDefaults.standard.set(groupKey, forKey: "lastGeneratedGroupCode")

        // Create user with new group
        createUser(name: name, email: email, groupName: groupName, password: password, groupKey: groupKey) { success, userInfo in
            completion(userInfo)
        }
    }
    
    // Registers a new user and joins an existing group
    // Validates that the group code exists before creating user
    func registerWithGroupCode(groupCode: String, completion: @escaping (UserInfo?) -> Void) {
        // Validate group code is not empty
        guard !groupCode.isEmpty else {
            errorMessage = "Please enter a group code"
            completion(nil)
            return
        }
        
        // Validate group code is a number
        guard let groupKeyInt = Int(groupCode) else {
            errorMessage = "Group code must be a 6-digit number"
            completion(nil)
            return
        }
        
        Task {
            do {
                print("DEBUG: Searching for groupKey: \(groupKeyInt) (type: Int)")
                
                // Check if group exists using pre-existing function
                let result = try await FirebaseInterface.shared.checkGroupExistsAsync(groupKey: groupKeyInt)
                
                // Verify group was found
                guard result.exists, let existingUserData = result.userData else {
                    await MainActor.run {
                        self.errorMessage = "Invalid group code. No group found with code: \(groupCode)"
                    }
                    completion(nil)
                    return
                }
                
                print("DEBUG: Found user data: \(existingUserData)")
                
                // Get the group name from existing user
                let actualGroupName = existingUserData["groupName"] as? String ?? "Home Group"
                
                // Create new user with the same group key
                let returnedUserData = try await FirebaseInterface.shared.addUser(
                    name: self.name,
                    email: self.email,
                    groupKey: groupKeyInt,
                    groupName: actualGroupName,
                    password: self.password
                )
                
                // Create UserInfo to return
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
