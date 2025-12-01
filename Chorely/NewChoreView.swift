//
//  NewChoreView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/25/25.
//

import SwiftUI

// Form view for creating a new chore
// Presented as a sheet from ChoresView
struct NewChoreView: View {
    // ViewModel handles form state and saving
    @StateObject var viewModel = NewChoreViewModel()
    
    // Binding to control sheet presentation
    @Binding var newChorePresented: Bool
    
    var body: some View {
        VStack {
            // Title
            Text("New Chore")
                .bold()
                .font(.system(size: 32))
                .padding(.top, 50)
            
            Form {
                // Chore title input
                TextField("Title", text: $viewModel.title)
                    .textFieldStyle(DefaultTextFieldStyle())
                
                // Due date picker with full calendar view
                DatePicker("Due Date", selection: $viewModel.dueDate)
                    .datePickerStyle(GraphicalDatePickerStyle())
                
                // Optional description input
                TextField("Description (optional)", text: $viewModel.description)
                    .textFieldStyle(DefaultTextFieldStyle())
                
                // Priority level selector (Low/Medium/High)
                Section {
                    Picker("Priority", selection: $viewModel.priorityLevel) {
                        Text("Low").tag("low")
                        Text("Medium").tag("medium")
                        Text("High").tag("high")
                    }
                    .pickerStyle(.segmented)
                }
                
                // Repetition frequency selector
                Section {
                    Picker("Repeat", selection: $viewModel.repetitionTime) {
                        Text("Does not repeat").tag("None")
                        Text("Daily").tag("Daily")
                        Text("Weekly").tag("Weekly")
                        Text("Monthly").tag("Monthly")
                        Text("Yearly").tag("Yearly")
                    }
                    .pickerStyle(.menu)
                }
                .padding(.bottom, 60)
                
                // Show loading state or save button
                if viewModel.isLoading {
                    Text("Loading your group...")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    // Save button
                    ChorelyButton(title: "Save", background: .pink) {
                        viewModel.save()
                        newChorePresented = false // Dismiss sheet
                    }
                    .padding()
                    .disabled(!viewModel.canSave)
                }
            }
            
            // Error alert if save fails
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text("Please enter a title and make sure you're in a group.")
                )
            }
        }
    }
}

#Preview {
    NewChoreView(newChorePresented: .constant(true))
}
