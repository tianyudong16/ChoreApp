//
//  CalendarViewModel.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/29/25.
//

import Foundation
import FirebaseFirestore
import SwiftUI

// Filter options for viewing chores
enum ChoreFilter: String, CaseIterable, Identifiable {
    case house = "House" // All chores in the group
    case mine = "Mine" // Only current user's chores
    case roommates = "Roommates" // Only roommates' chores
    
    var id: String { rawValue }
}

struct GroupMemberInfo: Identifiable {
    let id: String // User's Firebase UID
    let name: String
    let color: Color
    let colorString: String
}

// ViewModel for CalendarView and DailyTasksView
// Handles fetching chores and group members using FirebaseInterface
@MainActor
class CalendarViewModel: ObservableObject {
    @Published var chores: [String: Chore] = [:] // documentID : Chore
    @Published var groupMembers: [GroupMemberInfo] = []
    @Published var currentUserID: String = ""
    @Published var currentUserName: String = ""
    @Published var selectedFilter: ChoreFilter = .house
    @Published var isLoading = true
    @Published var errorMessage = ""
    
    
    private var groupKey: String?
    private var choresListener: ListenerRegistration?
    private var membersListener: ListenerRegistration?
    
    var choreIDs: [String] {
        Array(chores.keys)
    }
    
    var filteredChoreIDs: [String] {
        switch selectedFilter {
        case .house:
            return choreIDs
        case .mine:
            return choreIDs.filter { chores[$0]?.assignedUsers.contains(currentUserID) == true }
        case .roommates:
            return choreIDs.filter {
                guard let chore = chores[$0] else { return false }
                return !chore.assignedUsers.contains(currentUserID) && !chore.assignedUsers.isEmpty
            }
        }
    }
    
    func choresForDate(_ date: Date) -> [(id: String, chore: Chore)] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return filteredChoreIDs.compactMap { id in
            guard let chore = chores[id],
                  let choreDate = dateFormatter.date(from: chore.date),
                  calendar.isDate(choreDate, inSameDayAs: date) else { return nil }
            return (id, chore)
        }
    }
    
    func assigneeColorsForDate(_ date: Date) -> [Color] {
        let dayChores = choresForDate(date)
        var colors: [Color] = []
        
        for (_, chore) in dayChores {
            for userID in chore.assignedUsers {
                if let member = groupMembers.first(where: { $0.id == userID }) {
                    if !colors.contains(member.color) {
                        colors.append(member.color)
                    }
                }
            }
        }
        
        if colors.isEmpty && !dayChores.isEmpty {
            colors.append(.gray)
        }
        
        return colors
    }
    
    func dateHasChores(_ date: Date) -> Bool {
        return !choresForDate(date).isEmpty
    }
    
    func getMember(byID id: String) -> GroupMemberInfo? {
        return groupMembers.first(where: { $0.id == id })
    }
    
    func colorForUser(_ userID: String) -> Color {
        return getMember(byID: userID)?.color ?? .gray
    }
    
    func nameForUser(_ userID: String) -> String {
        return getMember(byID: userID)?.name ?? "Unknown"
    }
    
    func loadData(userID: String) {
        self.currentUserID = userID
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let userData = try await FirebaseInterface.shared.getUserData(uid: userID)
                let keys = FirebaseInterface.shared.extractGroupKey(from: userData)
                
                self.currentUserName = userData["Name"] as? String ?? "User"
                
                guard let keyString = keys.string else {
                    self.errorMessage = "No group key found"
                    self.isLoading = false
                    return
                }
                
                self.groupKey = keyString
                
                setupChoresListener(groupKey: keyString)
                if let intKey = keys.int {
                    setupMembersListener(groupKey: intKey)
                }
                
            } catch {
                self.errorMessage = "Error loading user: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func toggleChoreCompletion(choreID: String) {
        guard let groupKey = groupKey,
              let chore = chores[choreID] else { return }
        
        Task {
            if chore.completed {
                // Create a new Chore object with the updated completion status
                let updatedChore = Chore(
                    checklist: chore.checklist,
                    date: chore.date,
                    day: chore.day,
                    description: chore.description,
                    monthlyRepeatByDate: chore.monthlyRepeatByDate,
                    monthlyRepeatByWeek: chore.monthlyRepeatByWeek,
                    name: chore.name,
                    priorityLevel: chore.priorityLevel,
                    repetitionTime: chore.repetitionTime,
                    timeLength: chore.timeLength,
                    assignedUsers: chore.assignedUsers,
                    completed: false,
                    votes: chore.votes,
                    voters: chore.voters,
                    proposal: chore.proposal
                )
                
                // Use the existing editChore function
                editChore(documentId: choreID, chore: updatedChore, groupKey: groupKey) { success in
                    if success {
                        print("Chore unchecked successfully")
                    }
                }
            } else {
                await FirebaseInterface.shared.markComplete(
                    userName: currentUserName,
                    choreId: choreID,
                    groupKey: groupKey
                )
            }
        }
    }
    
    func deleteChore(choreID: String) {
        guard let groupKey = groupKey else { return }
        FirebaseInterface.shared.deleteChore(groupKey: groupKey, choreId: choreID)
    }
    
    private func setupChoresListener(groupKey: String) {
        choresListener?.remove()
        
        choresListener = FirebaseInterface.shared.addChoresListener(groupKey: groupKey) { [weak self] documents, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error loading chores: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = documents else {
                    self.chores = [:]
                    return
                }
                
                self.chores = self.readChoreDocuments(documents)
                print("Loaded \(self.chores.count) chores for calendar")
            }
        }
    }
    
    private func setupMembersListener(groupKey: Int) {
        membersListener?.remove()
        
        membersListener = FirebaseInterface.shared.addGroupMembersListener(groupKey: groupKey) { [weak self] documents, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("Error loading group members: \(error)")
                    return
                }
                
                guard let documents = documents else {
                    self.groupMembers = []
                    return
                }
                
                self.groupMembers = self.readMemberDocuments(documents)
                print("Loaded \(self.groupMembers.count) group members")
            }
        }
    }
    
    private func readChoreDocuments(_ documents: [QueryDocumentSnapshot]) -> [String: Chore] {
        var result: [String: Chore] = [:]
        
        for doc in documents {
            let data = doc.data()
            guard let name = data["Name"] as? String else { continue }
            
            let chore = Chore(
                checklist: data["Checklist"] as? Bool ?? false,
                date: data["Date"] as? String ?? "",
                day: data["Day"] as? String ?? "",
                description: data["Description"] as? String ?? " ",
                monthlyRepeatByDate: data["MonthlyRepeatByDate"] as? Bool ?? false,
                monthlyRepeatByWeek: data["MonthlyRepeatByWeek"] as? String ?? " ",
                name: name,
                priorityLevel: data["PriorityLevel"] as? String ?? "low",
                repetitionTime: data["RepetitionTime"] as? String ?? "None",
                timeLength: data["TimeLength"] as? Int ?? 0,
                assignedUsers: data["assignedUsers"] as? [String] ?? [],
                completed: data["completed"] as? Bool ?? false,
                votes: data["votes"] as? Int ?? 0,
                voters: data["voters"] as? [String] ?? [],
                proposal: data["proposal"] as? Bool ?? false
            )
            result[doc.documentID] = chore
        }
        
        return result
    }
    
    private func readMemberDocuments(_ documents: [QueryDocumentSnapshot]) -> [GroupMemberInfo] {
        return documents.compactMap { doc -> GroupMemberInfo? in
            let data = doc.data()
            guard let name = data["Name"] as? String else { return nil }
            
            let colorString = data["color"] as? String ?? "Green"
            let color = colorFromString(colorString)
            
            return GroupMemberInfo(
                id: doc.documentID,
                name: name,
                color: color,
                colorString: colorString
            )
        }
    }
    
    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red":
            return .red
        case "blue":
            return .blue
        case "green":
            return .green
        case "yellow":
            return .yellow
        case "orange":
            return .orange
        case "purple":
            return .purple
        case "pink":
            return .pink
        case "cyan":
            return .cyan
        case "mint":
            return .mint
        case "teal":
            return .teal
        case "indigo":
            return .indigo
        default:
            return .green
        }
    }
    
    func priorityRank(_ priority: String) -> Int {
        switch priority.lowercased() {
        case "high": return 0
        case "medium": return 1
        default: return 2
        }
    }
    
    deinit {
        choresListener?.remove()
        membersListener?.remove()
    }
}
