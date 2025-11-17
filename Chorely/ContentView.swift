//
//  ContentView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 10/30/25.
//
// This file handles login

import SwiftUI
import FirebaseFirestore

// Make a simple struct for navigation data
struct UserInfo: Hashable {
    let name: String
    let groupName: String
}
let db = FirebaseInterface.shared.firestore

//I (Milo) added a separate class called ContentViewModel,to help keep the wordy code from clogging up the ContentView code
@MainActor
final class ContentViewModel: ObservableObject {
    
    //I'm not calling createUser addUser to avoid confusion
    func createUser(name: String, email: String, groupName: String, password: String) {
        guard !name.isEmpty, !groupName.isEmpty else {
            print("no name or groupName found!")
            return
        }
        guard !password.isEmpty else {
            print("no password found!")
            return
        }
        guard !email.isEmpty else {
            print("no email found!")
            return
        }
        //It is important that we have the Task block here, so we don't need to add
        //a bunch of wordy code to support concurrency in the middle of our View
        Task {
            do {
                let returnedUserData = try await FirebaseInterface.shared.addUser(name: name,  email: email, groupName: groupName, password: password)
                print("success")
                print(returnedUserData)
            } catch {
                print("Error: \(error)")
            }
        }
    }
}

struct ContentView: View {
    // This state variable will control what view is shown
    // nil = Login Screen
    // UserInfo = Home Screen
    @State private var currentUser: UserInfo? = nil
    @State private var viewModel = ContentViewModel()
    // Original States (for login screen)
    @State private var showTextFields = false
    @State private var name = ""
    @State private var groupName = ""
    @State private var email = ""//Added a new field called email, because the FirebaseAuth package requires each user to have a unique email.
    @State private var password = ""//A password is also necessary
    
    var body: some View {
        // If a user is logged in, show the MainTabView
        // Otherwise, show the login screen
        if let user = currentUser {
            MainTabView(user: user)
        } else {
            NavigationStack {
                HeaderView() // I (Tian) created a new file to contain the header design elements
                
                // Login Form
                
                
                // Create an account
                
                Spacer()
                
//                VStack {
//                    
//                    Text("Welcome to Chorely")
//                        .font(.largeTitle)
//                        .fontWeight(.bold)
//                        .multilineTextAlignment(.center)
//                        .frame(maxWidth: .infinity, alignment: .center)
//                        .padding(.top, 200)
//                    
//                    Spacer()
//                    
//                    Button("Get Started") {
//                        withAnimation {
//                            showTextFields.toggle()
//                        }
//                    }
//                    .foregroundColor(Color(uiColor: .label))
//                    .frame(width: 200, height: 50)
//                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary, lineWidth: 2))
//                    .background(Color(uiColor: .systemBackground))
//                    
//                    Spacer()
//                    
//                    // Text Fields
//                    if showTextFields {
//                        VStack(spacing: 20) {
//                            TextField("Enter your name", text: $name)
//                                .textFieldStyle(.roundedBorder)
//                            TextField("Enter your group's name", text: $groupName)
//                                .textFieldStyle(.roundedBorder)
//                            TextField("Enter your email", text: $email)
//                                .textFieldStyle(.roundedBorder).textInputAutocapitalization(.never)
//                            TextField("Enter your password", text: $password)
//                                .textFieldStyle(.roundedBorder).textInputAutocapitalization(.never)
//                            
//                            Button("Let's Go!") {
//                                viewModel.createUser(name: name,  email: email, groupName: groupName, password: password)
//                                
//                                // Set the current user. This triggers the view swap to MainTabView
//                                withAnimation {
//                                    self.currentUser = UserInfo(name: name, groupName: groupName)
//                                }
//                            }
//                            .fontWeight(.bold)
//                            .italic()
//                            .disabled(name.isEmpty || groupName.isEmpty)
//                            
//
//                        }
//                        .padding(.horizontal, 40)
//                        .transition(.move(edge: .bottom).combined(with: .opacity))
//                    }
//                    
//                    Spacer()
//                }
//                .padding()
            }
        }
    }
}



#Preview {
    ContentView()
}
