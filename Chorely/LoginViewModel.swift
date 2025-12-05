//
//  LoginViewModel.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/17/25.
//

import Foundation
import FirebaseAuth

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage = ""
    
    func loginUser(email: String, password: String, completion: @escaping (Bool, UserInfo?) -> Void) {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address."
            completion(false, nil)
            return
        }
        guard !password.isEmpty else {
            errorMessage = "Please enter your password."
            completion(false, nil)
            return
        }
        
        
        Task {
            do {
                let returnedUserData = try await FirebaseInterface.shared.signIn(email: email, password: password)
                
                let userData = try await FirebaseInterface.shared.getUserData(uid: returnedUserData.uid)
                
                let name = userData["Name"] as? String ?? "User"
                let groupName = userData["groupName"] as? String ?? "Home"
                
                let userInfo = UserInfo(
                    uid: returnedUserData.uid,
                    name: name,
                    groupName: groupName,
                    email: returnedUserData.email ?? email
                )
                
                completion(true, userInfo)
                
            } catch {
                handleLoginError(error)
                completion(false, nil)
            }
        }
    }
    
    private func handleLoginError(_ error: Error) {
        let authError = AuthErrorCode(rawValue: (error as NSError).code)
        
        switch authError {
        case .wrongPassword, .invalidCredential:
            errorMessage = "Incorrect password or email. Please try again."
        case .userNotFound:
            errorMessage = "No account found with this email. Please register first."
        case .invalidEmail:
            errorMessage = "Please enter a valid email address."
        case .userDisabled:
            errorMessage = "This account has been disabled. Please contact support."
        case .networkError:
            errorMessage = "Network error. Please check your connection and try again."
        default:
            errorMessage = "Login failed. Please check your email and password."
        }
        
        print("Login error: \(error.localizedDescription)")
    }
}
