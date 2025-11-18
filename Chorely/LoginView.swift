//
//  LoginView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 10/30/25.
//
// This file handles login

import SwiftUI
import FirebaseFirestore

// Make a simple struct for navigation data

struct UserInfo: Hashable {
    let uid: String
    let name: String
    let groupName: String
    let email: String
}


let db = FirebaseInterface.shared.firestore

//
//  LoginView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 10/30/25.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var currentUser: UserInfo? = nil
    
    var body: some View {
        NavigationView {
            if let user = currentUser {
                MainTabView(user: user, onLogout: {
                    withAnimation {
                        currentUser = nil
                        viewModel.email = ""
                        viewModel.password = ""
                    }
                })
            } else {
                VStack {
                    HeaderView(title: "Welcome to Chorely", subtitle: "Start Organizing Chores!", angle: 15, background: Color(hue: 0.353, saturation: 1.0, brightness: 0.569))
                    
                    Form {
                        if !viewModel.errorMessage.isEmpty {
                            Text(viewModel.errorMessage)
                                .foregroundColor(Color.red)
                        }
                        
                        TextField("Email Address", text: $viewModel.email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .autocorrectionDisabled(true)
                        SecureField("Password", text: $viewModel.password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        ChorelyButton(
                            title: "Log In",
                            background: .blue
                        ) {
                            viewModel.loginUser(email: viewModel.email, password: viewModel.password) { success, userInfo in
                                if success, let userInfo = userInfo {
                                    currentUser = userInfo
                                }
                            }
                        }
                        .padding()
                    }
                    .offset(y: -50)
                    
                    VStack {
                        Text("New around here?")
                            .padding(.top, 5)
                            .padding(.bottom, 5)
                        
                        NavigationLink("Create An Account", destination: RegisterView { userInfo in
                            currentUser = userInfo
                        })
                    }
                    .padding(.bottom, 50)
                    
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    LoginView()
}
