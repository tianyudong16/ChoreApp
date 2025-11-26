//
//  NewChoreView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/25/25.
//

import SwiftUI

struct NewChoreView: View {
    @StateObject var viewModel = NewChoreViewModel()
    @Binding var newChorePresented: Bool
    
    var body: some View {
        VStack {
            Text("New Chore")
                .bold()
                .font(.system(size: 32))
                .padding(.top, 50)
        }
        
        Form {
            // Title
            TextField("Title", text: $viewModel.title)
                .textFieldStyle(DefaultTextFieldStyle())
            
            // Due Date
            DatePicker("Due Date", selection: $viewModel.dueDate)
                .datePickerStyle(GraphicalDatePickerStyle())
            
            // Button
            ChorelyButton(title: "Save",
                          background: .pink) {
                if viewModel.canSave {
                    viewModel.save()
                    newChorePresented = false
                } else {
                    viewModel.showAlert = true
                }
            }
            .padding()
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text("Error"),
                message: Text("Please fill in all fields and select due date that is today or newer.")
            )
        }
    }
}

#Preview {
    NewChoreView(newChorePresented: Binding(get: {
        return true
    }, set: { _ in
    }))
}
