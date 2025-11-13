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
    
    // Temporary UI state before Firebase chores are wired in
    @State private var showNewChoreSheet = false
    @State private var sampleChores: [ChoreItem] = [
        .init(name: "Take out trash", priority: 2),
        .init(name: "Clean dishes", priority: 1),
        .init(name: "Vacuum living room", priority: 3)
    ]
    
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
    
    // Helper to determine the title
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
                
                if sampleChores.isEmpty {
                    Text("No chores assigned yet.")
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                } else {
                    List {
                        ForEach(sampleChores) { chore in
                            choreRow(chore)
                        }
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
                AddChoreSheet { newChore in
                    sampleChores.append(newChore)
                }
            }
        }
    }
    
    // MARK: - CHORE ROW
    @ViewBuilder
    func choreRow(_ chore: ChoreItem) -> some View {
        HStack {
            Image(systemName: "circle")
                .font(.title2)
            
            VStack(alignment: .leading) {
                Text(chore.name)
                    .font(.headline)
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
}

//
// MARK: - CHORE ITEM MODEL
//

struct ChoreItem: Identifiable {
    let id = UUID()
    var name: String
    var priority: Int // 1=low, 2=med, 3=high
    
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
    
    @State private var name = ""
    @State private var priority = 2
    
    var onAdd: (ChoreItem) -> Void
    
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
            }
            .navigationTitle("Add Chore")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let newChore = ChoreItem(name: name, priority: priority)
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
