//
//  ContentView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 10/30/25.
//

import SwiftUI
import FirebaseFirestore

// Make a simple struct for navigation data
struct UserInfo: Hashable {
    let name: String
    let groupName: String
}

let db = FirebaseInterface.shared.firestore

struct ContentView: View {
    // This state variable will control what view is shown
    // nil = Login Screen
    // UserInfo = Home Screen
    @State private var currentUser: UserInfo? = nil
    
    // Original States (for login screen)
    @State private var showTextFields = false
    @State private var name = ""
    @State private var groupName = ""
    
    var body: some View {
        // If a user is logged in, show the MainTabView
        // Otherwise, show the login screen
        if let user = currentUser {
            MainTabView(user: user)
        } else {
            NavigationStack {
                VStack {
                    // App title centered at top
                    Text("Welcome to Chorely")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 200)
                    
                    Spacer()
                    
                    // Get Started button
                    Button("Get Started") {
                        withAnimation {
                            showTextFields.toggle()
                        }
                    }
                    .foregroundColor(Color(uiColor: .label))
                    .frame(width: 200, height: 50)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary, lineWidth: 2))
                    .background(Color(uiColor: .systemBackground))
                    
                    Spacer()
                    
                    // Text Fields
                    if showTextFields {
                        VStack(spacing: 20) {
                            TextField("Enter your name", text: $name)
                                .textFieldStyle(.roundedBorder)
                            TextField("Enter your group's name", text: $groupName)
                                .textFieldStyle(.roundedBorder)
                            
                            // Let's Go Button
                            Button("Let's Go!") {
                                // Call firebase
                                FirebaseInterface.shared.addUser(name: name, groupName: groupName)
                                
                                // Set the current user. This triggers the view swap to MainTabView
                                withAnimation {
                                    self.currentUser = UserInfo(name: name, groupName: groupName)
                                }
                            }
                            .fontWeight(.bold)
                            .italic()
                            .disabled(name.isEmpty || groupName.isEmpty)
                            

                        }
                        .padding(.horizontal, 40)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
}



#Preview {
    ContentView()
}
