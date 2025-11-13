//
//  ChoresView.swift
//  Chorely
//
//  Created by Brooke Tanner on 11/11/25.
//  Edited by Tian Yu Dong on 11/12/25

import SwiftUI

struct ChoresView: View {
    
    let user: UserInfo
    let selectedDate: Date?
    
    @State private var showNewChoreSheet = false
    @State private var chores: [ChoreItem] = []
    
    // 1. Init for HomeView (takes no date)
    init(user: UserInfo) {
        self.user = user
        self.selectedDate = nil
    }
    
    // 2. Init for CalendarView (takes a date)
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
    
    var body: some View {
        NavigationStack {
            VStack {
                
                if chores.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No chores yet")
                            .font(.title3)
                            .foregroundColor(.gray)
                        Text("Tap + to add your first chore")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 60)
                } else {
                    List {
                        ForEach(chores) { chore in
                            choreRow(chore)
                        }
                        .onDelete(perform: deleteChores)
                    }
                    .listStyle(.insetGrouped)
                }
                
                Spacer()
                
            }
            .navigationTitle(navigationTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showNewChoreSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showNewChoreSheet) {
                AddChoreSheet(user: user) { newChore in
                    chores.append(newChore)
                    saveChoreToFirebase(newChore)
                }
            }
            .onAppear {
                loadChores()
            }
        }
    }
    
    // MARK: - LOAD CHORES
    private func loadChores() {
        FirebaseInterface.shared.fetchChores(groupID: user.groupID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedChores):
                    self.chores = fetchedChores
                case .failure(let error):
                    print("Error loading chores: \(error)")
                }
            }
        }
    }
    
    // MARK: - SAVE CHORE
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
    
    // MARK: - DELETE CHORES
    private func deleteChores(at offsets: IndexSet) {
        for index in offsets {
            let chore = chores[index]
            FirebaseInterface.shared.deleteChore(choreID: chore.id.uuidString, groupID: user.groupID)
        }
        chores.remove(atOffsets: offsets)
    }
    
    // MARK: - CHORE ROW
    @ViewBuilder
    func choreRow(_ chore: ChoreItem) -> some View {
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
                    Text("Assigned to: \(chore.assignedTo)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Text("Priority: \(chore.priorityName)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Priority Dots
            HStack(spacing: 4) {
                ForEach(1...3, id: \.self) { i in
                    Circle()
                        .fill(i <= chore.priority ? .red : .gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }
        }
    }
    
    // MARK: - TOGGLE COMPLETION
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

//
// MARK: - CHORE ITEM MODEL
//

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
    
    init(
        id: UUID = UUID(),
        name: String,
        priority: Int = 2,
        assignedTo: String = "",
        isCompleted: Bool = false,
        dueDate: Date? = nil,
        repetition: String = "none",
        estimatedTime: Int = 30,
        description: String = ""
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

//
// MARK: - ADD CHORE SHEET
//

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
                    TextField("Assigned to (leave blank for shared)", text: $assignedTo)
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
                            assignedTo: assignedTo,
                            isCompleted: false,
                            dueDate: hasDueDate ? dueDate : nil,
                            repetition: repetition,
                            estimatedTime: estimatedTime,
                            description: description
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
