//
//  ChoresView.swift
//  Chorely
//
//  Created by Brooke Tanner on 11/11/25.
//

import SwiftUI

struct ChoresView: View {
    
    let user: UserInfo
    let selectedDate: Date?
    
    @State private var showNewChoreSheet = false
    @State private var showFilterSheet = false
    @State private var chores: [ChoreItem] = []
    @State private var members: [GroupMember] = []
    
    // Filter states
    @State private var filterOption: FilterOption = .all
    
    enum FilterOption: String, CaseIterable {
        case all = "All Tasks"
        case completed = "Completed"
        case uncompleted = "Uncompleted"
        case daily = "Daily Tasks"
        case priorityLow = "Low Priority"
        case priorityMedium = "Medium Priority"
        case priorityHigh = "High Priority"
    }
    
    //Init for HomeView (takes no date)
    init(user: UserInfo) {
        self.user = user
        self.selectedDate = nil
    }
    
    //Init for CalendarView (takes a date)
    init(user: UserInfo, selectedDate: Date) {
        self.user = user
        self.selectedDate = selectedDate
    }
    
    private var navigationTitle: String {
        if let selectedDate = selectedDate {
            return selectedDate.monthYearString()
        } else {
            return "All Chores"
        }
    }
    
    // Filtered chores based on selected filter
    private var filteredChores: [ChoreItem] {
        switch filterOption {
        case .all:
            return chores
        case .completed:
            return chores.filter { $0.isCompleted }
        case .uncompleted:
            return chores.filter { !$0.isCompleted }
        case .daily:
            return chores.filter { $0.repetition == "daily" }
        case .priorityLow:
            return chores.filter { $0.priority == 1 }
        case .priorityMedium:
            return chores.filter { $0.priority == 2 }
        case .priorityHigh:
            return chores.filter { $0.priority == 3 }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Header
            HStack {
                Text("Chores")
                    .font(.title2.bold())
                
                Spacer()
                
                Button {
                    showFilterSheet = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 10)
            
            // Handles filtering
            if filterOption != .all {
                HStack {
                    Text("Filtered by: \(filterOption.rawValue)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(12)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            if filteredChores.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text(filterOption == .all ? "No chores yet" : "No chores match this filter")
                        .font(.title3)
                        .foregroundColor(.gray)
                    if filterOption == .all {
                        Text("Tap 'Add Chore' to create your first chore")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredChores) { chore in
                        choreRow(chore)
                    }
                    .onDelete(perform: deleteChores)
                }
                .listStyle(.insetGrouped)
            }
            
            // Add Chores Button
            Button {
                showNewChoreSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text("Add Chore")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding()
            
        }
        .sheet(isPresented: $showNewChoreSheet) {
            AddChoreSheet(user: user) { newChore in
                chores.append(newChore)
                saveChoreToFirebase(newChore)
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            FilterSheet(selectedFilter: $filterOption)
        }
        .onAppear {
            loadChores()
            loadMembers()
        }
    }
    
    // Load group members
    private func loadMembers() {
        FirebaseInterface.shared.listenToGroupMembers(groupID: user.groupID) { updatedMembers in
            DispatchQueue.main.async {
                self.members = updatedMembers
            }
        }
    }
    
    // Load chores
    private func loadChores() {
        FirebaseInterface.shared.fetchChores(groupID: user.groupID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedChores):
                    // Filter out pending chores - they only show in Home pending approvals
                    self.chores = fetchedChores.filter { !$0.isPending }
                case .failure(let error):
                    print("Error loading chores: \(error)")
                }
            }
        }
    }
    
    // Saving chores
    private func saveChoreToFirebase(_ chore: ChoreItem) {
        FirebaseInterface.shared.saveChore(chore: chore, groupID: user.groupID) { result in
            switch result {
            case .success:
                print("Chore saved successfully")
            case .failure(let error):
                print("Error saving chore: \(error)")
            }
        }
    }
    
    // Deleting chores
    private func deleteChores(at offsets: IndexSet) {
        for index in offsets {
            let chore = filteredChores[index]
            FirebaseInterface.shared.deleteChore(choreID: chore.id.uuidString, groupID: user.groupID)
            chores.removeAll { $0.id == chore.id }
        }
    }
    
    // Showing all chores
    @ViewBuilder
    func choreRow(_ chore: ChoreItem) -> some View {
        let assignedMember = members.first(where: { $0.name == chore.assignedTo })
        let backgroundColor = assignedMember != nil ? Color.fromData(assignedMember!.colorData).opacity(0.15) : Color(.systemGray6)
        
        HStack {
            Button {
                toggleChoreCompletion(chore)
            } label: {
                Image(systemName: chore.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(chore.isCompleted ? .green : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(chore.name)
                    .font(.headline)
                    .strikethrough(chore.isCompleted)
                
                if !chore.assignedTo.isEmpty {
                    HStack(spacing: 6) {
                        if let member = assignedMember {
                            Circle()
                                .fill(Color.fromData(member.colorData))
                                .frame(width: 12, height: 12)
                        }
                        Text("Assigned to: \(chore.assignedTo)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Text("Priority: \(chore.priorityName)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Priority levels
            HStack(spacing: 4) {
                ForEach(1...3, id: \.self) { i in
                    Circle()
                        .fill(i <= chore.priority ? .red : .gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(10)
    }
    
    // Toggling completion
    private func toggleChoreCompletion(_ chore: ChoreItem) {
        if let index = chores.firstIndex(where: { $0.id == chore.id }) {
            chores[index].isCompleted.toggle()
            FirebaseInterface.shared.updateChoreCompletion(
                choreID: chore.id.uuidString,
                groupID: user.groupID,
                isCompleted: chores[index].isCompleted
            )
        }
    }
}

// Model for chore items

struct ChoreItem: Identifiable, Codable {
    let id: UUID
    var name: String
    var priority: Int // 1=low, 2=med, 3=high
    var assignedTo: String
    var isCompleted: Bool
    var dueDate: Date?
    var repetition: String // "none", "daily", "weekly", "monthly"
    var estimatedTime: Int // in minutes
    var description: String
    var isPending: Bool //For approval system
    var proposedBy: String //Who proposed this chore
    
    init(
        id: UUID = UUID(),
        name: String,
        priority: Int = 2,
        assignedTo: String = "",
        isCompleted: Bool = false,
        dueDate: Date? = nil,
        repetition: String = "none",
        estimatedTime: Int = 30,
        description: String = "",
        isPending: Bool = false,
        proposedBy: String = ""
    ) {
        self.id = id
        self.name = name
        self.priority = priority
        self.assignedTo = assignedTo
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.repetition = repetition
        self.estimatedTime = estimatedTime
        self.description = description
        self.isPending = isPending
        self.proposedBy = proposedBy
    }
    
    var priorityName: String {
        switch priority {
        case 1: return "Low"
        case 2: return "Medium"
        case 3: return "High"
        default: return "Unknown"
        }
    }
}

// Adding chores sheet

struct AddChoreSheet: View {
    
    @Environment(\.dismiss) var dismiss
    
    let user: UserInfo
    var onAdd: (ChoreItem) -> Void
    
    @State private var name = ""
    @State private var priority = 2
    @State private var assignedTo = ""
    @State private var repetition = "none"
    @State private var estimatedTime = 30
    @State private var description = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var assignToHouse = false // Toggles for assigning chore to house group
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Chore Details") {
                    TextField("Chore name", text: $name)
                    
                    Picker("Priority", selection: $priority) {
                        Text("Low").tag(1)
                        Text("Medium").tag(2)
                        Text("High").tag(3)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Assignment") {
                    Toggle("Assign to House (Requires Approval)", isOn: $assignToHouse)
                        .tint(.blue)
                    
                    if !assignToHouse {
                        TextField("Assigned to (leave blank for shared)", text: $assignedTo)
                    } else {
                        Text("This chore will be proposed to all house members for approval")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Section("Schedule") {
                    Picker("Repetition", selection: $repetition) {
                        Text("None").tag("none")
                        Text("Daily").tag("daily")
                        Text("Weekly").tag("weekly")
                        Text("Monthly").tag("monthly")
                    }
                    
                    Toggle("Set due date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                    }
                }
                
                Section("Time & Details") {
                    Stepper("Estimated time: \(estimatedTime) min", value: $estimatedTime, in: 5...120, step: 5)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Chore")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let newChore = ChoreItem(
                            name: name,
                            priority: priority,
                            assignedTo: assignToHouse ? "" : assignedTo,
                            isCompleted: false,
                            dueDate: hasDueDate ? dueDate : nil,
                            repetition: repetition,
                            estimatedTime: estimatedTime,
                            description: description,
                            isPending: assignToHouse, // Mark as pending if assigned to house
                            proposedBy: user.name // Track who proposed it
                        )
                        onAdd(newChore)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// Handles filter options

struct FilterSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedFilter: ChoresView.FilterOption
    
    var body: some View {
        NavigationStack {
            List {
                Section("Filter Options") {
                    ForEach(ChoresView.FilterOption.allCases, id: \.self) { option in
                        Button {
                            selectedFilter = option
                            dismiss()
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedFilter == option {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter Chores")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let previewUser = UserInfo(
        uid: "123",
        name: "Preview",
        email: "test@email.com",
        groupID: "group1",
        photoURL: "",
        colorData: UIColor.systemPink.toData() ?? Data()
    )
    
    return ChoresView(user: previewUser)
}
