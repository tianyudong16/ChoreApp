//
//  LoginViewModel.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/17/25.
//

import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage = ""
    
    // Milo's loginUser function
    func loginUser(email: String, password: String, completion: @escaping (Bool, UserInfo?) -> Void) {
        guard !email.isEmpty else {
            errorMessage = "No email found!"
            print("no email found!")
            completion(false, nil)
            return
        }
        guard !password.isEmpty else {
            errorMessage = "No password found!"
            print("no password found!")
            completion(false, nil)
            return
        }
        
        Task {
            do {
                let returnedUserData = try await FirebaseInterface.shared.signIn(email: email, password: password)
                print("success")
                print(returnedUserData)
                
                // Fetch user data from Firestore
                let userData = try await FirebaseInterface.shared.getUserData(uid: returnedUserData.uid)
                
                // Note: Use "Name" (capitalized) to match what's stored in Firestore
                let name = userData["Name"] as? String ?? "User" // Changed from "name" to "Name"
                let groupName = userData["groupName"] as? String ?? "Home"
                
                let userInfo = UserInfo(
                    uid: returnedUserData.uid,
                    name: name,
                    groupName: groupName,
                    email: returnedUserData.email ?? email
                )
                
                completion(true, userInfo)
                
            } catch {
                print("Error: \(error)")
                // ADDED ERROR HANDLING FOR NON-EXISTENT USER
                if let authError = error as NSError? {
                    if authError.code == 17004 || authError.code == 17011 {
                        errorMessage = "No account found. Please register first."
                    } else {
                        errorMessage = "Login failed: \(error.localizedDescription)"
                    }
                } else {
                    errorMessage = "Login failed: \(error.localizedDescription)"
                }
                completion(false, nil)
            }
        }
    }
}
