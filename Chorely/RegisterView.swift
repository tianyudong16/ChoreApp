//
//  RegisterView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/17/25.
//

import SwiftUI

struct RegisterView: View {
    @StateObject private var viewModel = RegisterViewModel()
    var onRegistrationComplete: (UserInfo) -> Void
    
    @State private var hasGroup: Bool? = nil
    @State private var groupCode = ""
    @State private var showingGroupCodeAlert = false
    @State private var generatedGroupCode = ""
    @State private var pendingUserInfo: UserInfo? = nil  // Store user info until alert is dismissed
    
    var body: some View {
        VStack {
            HeaderView(title: "Create An Account",
                       subtitle: "Organize your chores today!",
                       angle: -15,
                       background: .yellow)
            
            Form {
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                }
                
                TextField("Full Name", text: $viewModel.name)
                    .textFieldStyle(DefaultTextFieldStyle())
                    .autocorrectionDisabled(true)
                TextField("Email Address", text: $viewModel.email)
                    .textFieldStyle(DefaultTextFieldStyle())
                    .autocapitalization(.none)
                    .autocorrectionDisabled(true)
                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(DefaultTextFieldStyle())
                
                if hasGroup == nil {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Do you have an existing group?")
                            .font(.headline)
                        
                        HStack {
                            Button("Yes, I have a group code") {
                                withAnimation {
                                    hasGroup = true
                                }
                            }
                            .buttonStyle(BorderedButtonStyle())
                            .tint(.blue)
                            
                            Button("No, create new group") {
                                withAnimation {
                                    hasGroup = false
                                }
                            }
                            .buttonStyle(BorderedButtonStyle())
                            .tint(.green)
                        }
                    }
                    .padding(.vertical, 8)
                } else if hasGroup == true {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter Group Code")
                            .font(.headline)
                        
                        TextField("Enter your 6-digit group code", text: $groupCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .autocorrectionDisabled(true)
                            .keyboardType(.numberPad)
                        
                        Button("Back") {
                            withAnimation {
                                hasGroup = nil
                                groupCode = ""
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(.vertical, 8)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create New Group")
                            .font(.headline)
                        
                        TextField("Group Name", text: $viewModel.groupName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button("Back") {
                            withAnimation {
                                hasGroup = nil
                                viewModel.groupName = ""
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(.vertical, 8)
                }
                
                // handles user not having a group
                if hasGroup != nil {
                    let canRegister: Bool = {
                        if hasGroup == true {
                            return !viewModel.name.isEmpty &&
                                   !viewModel.email.isEmpty &&
                                   !viewModel.password.isEmpty &&
                                   !groupCode.isEmpty
                        } else {
                            return !viewModel.name.isEmpty &&
                                   !viewModel.email.isEmpty &&
                                   !viewModel.password.isEmpty &&
                                   !viewModel.groupName.isEmpty
                        }
                    }()
                    
                    ChorelyButton(
                        title: "Create Account",
                        background: canRegister ? .green : .gray
                    ) {
                        if hasGroup == true {
                            viewModel.registerWithGroupCode(groupCode: groupCode) { userInfo in
                                if let userInfo = userInfo {
                                    onRegistrationComplete(userInfo)
                                }
                            }
                        } else {
                            viewModel.register { userInfo in
                                if let userInfo = userInfo {
                                    // Store user info and get group code BEFORE showing alert
                                    pendingUserInfo = userInfo
                                    if let code = UserDefaults.standard.value(forKey: "lastGeneratedGroupCode") as? Int {
                                        generatedGroupCode = "\(code)"
                                    }
                                    showingGroupCodeAlert = true
                                }
                            }
                        }
                    }
                    .disabled(!canRegister)
                    .padding()
                }
            }
            .offset(y: -50)
            Spacer()
        }
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Group Created Successfully!", isPresented: $showingGroupCodeAlert) {
            Button("OK", role: .cancel) {
                // Complete registration AFTER user dismisses the alert
                if let userInfo = pendingUserInfo {
                    onRegistrationComplete(userInfo)
                }
            }
        } message: {
            Text("Your group code is: \(generatedGroupCode)\n\nShare this code with your roommates so they can join your group!")
        }
    }
}

#Preview {
    RegisterView { _ in }
}
