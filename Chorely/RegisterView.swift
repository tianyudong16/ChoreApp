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
                TextField("Group Name", text: $viewModel.groupName)
                    .textFieldStyle(DefaultTextFieldStyle())
                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(DefaultTextFieldStyle())
                
                ChorelyButton(
                    title: "Create Account",
                    background: .green
                ) {
                    viewModel.register { userInfo in
                        if let userInfo = userInfo {
                            onRegistrationComplete(userInfo)
                        }
                    }
                }
                .padding()
            }
            .offset(y: -50)
            Spacer()
        }
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    RegisterView { _ in }
}
