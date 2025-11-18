//
//  RegisterView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/17/25.
//

import SwiftUI

struct RegisterView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var groupName = ""
    
    var body: some View {
        VStack {
            // Header
            HeaderView(title: "Create An Account",
                       subtitle: "Organize your chores today!",
                       angle: -15,
                       background: .yellow)
            
            Form {
                TextField("Full Name", text: $name)
                    .textFieldStyle(DefaultTextFieldStyle())
                    .autocorrectionDisabled(true)
                TextField("Email Address", text: $email)
                    .textFieldStyle(DefaultTextFieldStyle())
                    .autocapitalization(.none)
                    .autocorrectionDisabled(true)
                TextField("Group's Name", text: $groupName)
                    .textFieldStyle(DefaultTextFieldStyle())
                SecureField("Create Password", text: $password)
                    .textFieldStyle(DefaultTextFieldStyle())
                
                ChorelyButton(
                    title: "Create Account",
                    background: .green
                ) {
                    // Attempt registration
                    
                }
                .padding()
            }
            .offset(y: -50)
            Spacer()
        }
    }
}

#Preview {
    RegisterView()
}
