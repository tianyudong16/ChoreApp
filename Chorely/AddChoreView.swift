//
//  AddChoreView.swift
//  Chorely
//
//  Created by Brooke Tanner on 11/19/25.
//
//  Tutorial reference: https://www.youtube.com/watch?v=EEcmRaeZ7ik

import SwiftUI

// Placeholder view for adding chores via a dropdown menu
// Currently contains sample UI - not yet fully implemented
struct AddChoreView: View {
    var body: some View {
        VStack {
            // Dropdown menu for selecting a chore
            Menu {
                Button("Chore") {
                    // TODO: Handle chore selection
                }
                Button("Chore 2") {
                    // TODO: Handle chore selection
                }
                Button("Chore 3") {
                    // TODO: Handle chore selection
                }
            }
            label: {
                Label("Select Chore", systemImage: "menucard")
            }
        }
        .padding()
    }
}

#Preview {
    AddChoreView()
}
