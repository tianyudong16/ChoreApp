//
//  ContentView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 10/30/25.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    
    @State private var isRegistering = false
    
    // Login fields - NOW USING EMAIL
    @State private var loginEmail = ""
    @State private var loginPassword = ""
    
    // Registration fields
    @State private var regName = ""
    @State private var regEmail = ""
    @State private var regPassword = ""
    @State private var regGroupName = ""
    @State private var regGroupPassword = ""
    
    @State private var errorMessage = ""
    @State private var showError = false
    
    @State private var loggedInUser: UserInfo? = nil
    
    var body: some View {
        VStack(spacing: 25) {
            
            // Remove Chorely title - let the view speak for itself
            if loggedInUser == nil {
                if isRegistering {
                    Text("Sign Up")
                        .font(.largeTitle.bold())
                        .padding(.top, 40)
                        .padding(.bottom, 100)
                    registrationView
                } else {
                    Text("Welcome to Chorely!")
                        .font(.largeTitle.bold())
                        .padding(.top, 100)
                        .padding(.bottom, 100)
                    
                    loginView
                }
            } else {
                MainTabView(user: loggedInUser!)
            }
            
            Spacer()
        }
        .padding()
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
}

//
// MARK: - LOGIN VIEW
//

extension ContentView {
    
    var loginView: some View {
        VStack(spacing: 18) {
            
            // Changed to Email instead of Name
            TextField("Email", text: $loginEmail)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $loginPassword)
                .textFieldStyle(.roundedBorder)
            
            Button(action: loginUser) {
                Text("Log In")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
            
            Button("Create an account") {
                isRegistering = true
            }
            .padding(.top, 5)
        }
    }
    
    func loginUser() {
        // Simplified login - just use email + password directly
        Auth.auth().signIn(withEmail: loginEmail, password: loginPassword) { authResult, error in
            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                    showError = true
                }
                return
            }
            
            guard let uid = authResult?.user.uid else { return }
            
            // Fetch user data from Firestore
            FirebaseInterface.shared.fetchUser(uid: uid) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let user):
                        self.loggedInUser = user
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }
        }
    }
}

//
// MARK: - SIGN UP VIEW
//

extension ContentView {
    
    var registrationView: some View {
        VStack(spacing: 18) {
            TextField("Your Name", text: $regName)
                .textFieldStyle(.roundedBorder)
            
            TextField("Email", text: $regEmail)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $regPassword)
                .textFieldStyle(.roundedBorder)
            
            TextField("Group Name", text: $regGroupName)
                .textFieldStyle(.roundedBorder)
            
            SecureField("Group Password", text: $regGroupPassword)
                .textFieldStyle(.roundedBorder)
            
            Button(action: registerUser) {
                Text("Sign Up")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
            
            Button("Already have an account? Log in") {
                isRegistering = false
            }
            .padding(.top, 5)
        }
    }
    
    func registerUser() {
        FirebaseInterface.shared.signUp(
            name: regName,
            email: regEmail,
            password: regPassword,
            groupName: regGroupName,
            groupPassword: regGroupPassword
        ) { result in
            
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    self.loggedInUser = user
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
