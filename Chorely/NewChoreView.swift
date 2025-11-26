//
//  NewChoreView.swift
//  Chorely
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
            
            Form {
                TextField("Title", text: $viewModel.title)
                    .textFieldStyle(DefaultTextFieldStyle())
                
                DatePicker("Due Date", selection: $viewModel.dueDate)
                    .datePickerStyle(GraphicalDatePickerStyle())
                
                TextField("Description (optional)", text: $viewModel.description)
                    .textFieldStyle(DefaultTextFieldStyle())
                
                Section {
                    Picker("Priority", selection: $viewModel.priorityLevel) {
                        Text("Low").tag("low")
                        Text("Medium").tag("medium")
                        Text("High").tag("high")
                    }
                    .pickerStyle(.segmented)
                }
                
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
                
                // Loading or Save Button
                if viewModel.isLoading {
                    Text("Loading your group...")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ChorelyButton(title: "Save", background: .pink) {
                        viewModel.save()
                        newChorePresented = false
                    }
                    .padding()
                    .disabled(!viewModel.canSave)
                }
            }
            
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
