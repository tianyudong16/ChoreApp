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
    
    // Milo's exact createUser function
    func createUser(name: String, email: String, groupName: String, password: String, completion: @escaping (Bool, UserInfo?) -> Void) {
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
                let returnedUserData = try await FirebaseInterface.shared.addUser(name: name, email: email, groupName: groupName, password: password)
                print("success")
                print(returnedUserData)
                
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
        // Use Milo's createUser directly
        createUser(name: name, email: email, groupName: groupName, password: password) { success, userInfo in
            completion(userInfo)
        }
    }
}
