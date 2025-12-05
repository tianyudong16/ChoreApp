//
//  NewChoreView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/25/25.
//

import SwiftUI

// Form view for creating or editing a chore
// Presented as a sheet from ChoresView or DailyTasksView
struct NewChoreView: View {
    @StateObject var viewModel = NewChoreViewModel()
    @Binding var newChorePresented: Bool
    
    // Optional parameters for edit mode
    private var editingChoreID: String?
    private var editingChore: Chore?
    
    // Initializer for creating a new chore
    init(newChorePresented: Binding<Bool>) {
        self._newChorePresented = newChorePresented
        self.editingChoreID = nil
        self.editingChore = nil
    }
    
    // Initializer for editing an existing chore
    init(newChorePresented: Binding<Bool>, choreID: String, chore: Chore) {
        self._newChorePresented = newChorePresented
        self.editingChoreID = choreID
        self.editingChore = chore
    }
    
    var body: some View {
        VStack {
            headerSection
            
            Text(viewModel.isEditing ? "Edit Chore" : "New Chore")
                .bold()
                .font(.system(size: 32))
                .padding(.top, 50)
            
            Form {
                titleField
                dueDatePicker
                descriptionField
                priorityPicker
                repeatPicker
                timeLengthPicker
                assigneePicker
                saveButtonSection
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text("Please enter a title and make sure you're in a group.")
                )
            }
        }
        .onAppear {
            configureEditModeIfNeeded()
        }
    }
    
    private var headerSection: some View {
        HStack {
            Button("Cancel") {
                newChorePresented = false
            }
            .foregroundColor(.red)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private var titleField: some View {
        TextField("Title", text: $viewModel.title)
            .textFieldStyle(DefaultTextFieldStyle())
    }
    
    private var dueDatePicker: some View {
        DatePicker("Due Date", selection: $viewModel.dueDate)
            .datePickerStyle(GraphicalDatePickerStyle())
    }
    
    private var descriptionField: some View {
        TextField("Description (optional)", text: $viewModel.description)
            .textFieldStyle(DefaultTextFieldStyle())
    }
    
    private var priorityPicker: some View {
        Section(header: Text("Priority")) {
            Picker("Priority", selection: $viewModel.priorityLevel) {
                Text("Low").tag("low")
                Text("Medium").tag("medium")
                Text("High").tag("high")
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var repeatPicker: some View {
        Section(header: Text("Repeat")) {
            Picker("Repeat", selection: $viewModel.repetitionTime) {
                Text("Does not repeat").tag("None")
                Text("Daily").tag("Daily")
                Text("Weekly").tag("Weekly")
                Text("Monthly").tag("Monthly")
                Text("Yearly").tag("Yearly")
            }
            .pickerStyle(.menu)
        }
    }
    
    private var timeLengthPicker: some View {
        Section(header: Text("Time Length")) {
            Picker("Duration", selection: $viewModel.timeLength) {
                Text("5 minutes").tag(5)
                Text("10 minutes").tag(10)
                Text("15 minutes").tag(15)
                Text("30 minutes").tag(30)
                Text("45 minutes").tag(45)
                Text("1 hour").tag(60)
            }
        }
    }
    
    private var assigneePicker: some View {
        Section(header: Text("Assign To")) {
            if viewModel.isLoading {
                Text("Loading group members...")
                    .foregroundColor(.secondary)
                    .italic()
            } else if viewModel.groupMembers.isEmpty {
                Text("No group members found")
                    .foregroundColor(.secondary)
            } else {
                Picker("Roommate", selection: $viewModel.selectedAssignee) {
                    Text("Unassigned").tag(nil as String?)
                    ForEach(viewModel.groupMembers) { member in
                        HStack {
                            Circle()
                                .fill(member.color)
                                .frame(width: 10, height: 10)
                            Text(member.name)
                        }
                        .tag(member.name as String?)
                    }
                }
            }
        }
        .padding(.bottom, 40)
    }
    
    private var saveButtonSection: some View {
        Group {
            if viewModel.isLoading {
                Text("Loading your group...")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ChorelyButton(
                    title: viewModel.isEditing ? "Save Changes" : "Save",
                    background: viewModel.canSave ? .pink : .gray
                ) {
                    if viewModel.canSave {
                        viewModel.save()
                        newChorePresented = false
                    }
                }
                .padding()
            }
        }
    }
    
    private func configureEditModeIfNeeded() {
        if let choreID = editingChoreID, let chore = editingChore {
            viewModel.configureForEditing(choreID: choreID, chore: chore)
        }
    }
}

#Preview {
    NewChoreView(newChorePresented: .constant(true))
}
