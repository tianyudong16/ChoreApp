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
//
//  AddChoreView.swift
//  Chorely
//
//  Created by Brooke Tanner on 11/19/25.
// used this tutorial //https://www.youtube.com/watch?v=EEcmRaeZ7ik
//https://www.youtube.com/watch?v=xx4ke5Ds8W0
//https://www.youtube.com/watch?v=GX47JnaY3cQ

import SwiftUI

struct AddChoreView: View {
    @State private var choreName: ChoreName? = nil
    @State private var priority: PriorityInput = .medium
    @State private var repetition: RepetitionInput = .once
    @State private var time: String = ""
    @State private var assignedUser: String? = nil
    @State private var groupMembers: [(id: String, name: String)] = []
    @State private var groupKey: String? = nil
    @Environment(\.dismiss) var dismiss
    
    
    
    var body: some View {
        VStack(spacing: 20) {
            
            Text("Add New Chore")
                .font(.largeTitle.bold())
                .padding(.top, 20)
            
            ZStack{
                RoundedRectangle(cornerRadius: 10)
                    .fill(.green.opacity(0.25))
                    .frame(height: 500)
                    .frame(maxWidth: 375)
                VStack{
                    ZStack{
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.white.opacity(1))
                            .frame(height: 100)
                            .frame(maxWidth: 350)
                        Menu {
                            Picker("", selection: $choreName) {
                                ForEach(ChoreName.allCases) { choreOption in
                                    Text(choreOption.rawValue.capitalized).tag(Optional(choreOption))
                                }
                            }
                        } label: {
                            Label {
                                Text(choreName == nil
                                     ? "Select Chore"
                                     : choreName!.rawValue.capitalized)
                                .foregroundColor(choreName == nil ? .gray : .black)
                                .font(.system(size: 22, weight: .semibold))
                            } icon: {
                                Image(systemName: "menucard")
                            }
                        }
                    }
                    ZStack{
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.white.opacity(1))
                            .frame(height: 100)
                            .frame(maxWidth: 350)
                        Menu {
                            Divider()
                            
                            Picker("", selection: $priority) {
                                ForEach(PriorityInput.allCases) { p in
                                    Text(p.rawValue.capitalized)
                                        .foregroundColor(p.color)
                                        .font(.system(size: 20))
                                        .tag(p)
                                }
                            }
                        } label: {
                            Label {
                                Text("Priority: \(priority.rawValue.capitalized)")
                                    .foregroundColor(priority.color)
                                    .font(.system(size: 22, weight: .semibold))
                            } icon: {
                                Image(systemName: "flag.fill")
                                    .foregroundColor(priority.color)
                            }
                        }
                    }
                    
                    ZStack{
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.white.opacity(1))
                            .frame(height: 100)
                            .frame(maxWidth: 350)
                        Menu {
                            Divider()
                            
                            Picker("", selection: $repetition) {
                                ForEach(RepetitionInput.allCases) { repetitionOption in
                                    Text(repetitionOption.rawValue)
                                        .tag(repetitionOption)
                                }
                            }
                        } label: {
                            Label("Repetition", systemImage: "arrow.triangle.2.circlepath")
                                .font(.system(size: 22, weight: .semibold))
                        }
                    }
                    ZStack{
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.white.opacity(1))
                            .frame(height: 100)
                            .frame(maxWidth: 350)
                        Menu {
                            Divider()
                            
                            Picker("", selection: $choreName) {
                                ForEach(ChoreName.allCases) { choreOption in
                                    Text(choreOption.rawValue)
                                        .tag(choreOption)
                                }
                            }
                        } label: {Label("Select Chore", systemImage: "menucard")
                        }
                    }
                }
                .padding()
            }
        }
    }
}


enum ChoreName: String, CaseIterable, Identifiable {
    case chore1
    case chore2
    case chore3

    var id: String { self.rawValue }
}

enum PriorityInput: String, CaseIterable, Identifiable {
    case high
    case medium
    case low

    var id: String { self.rawValue }
}

extension PriorityInput {
    var color: Color {
        switch self {
        case .low:    return .green
        case .medium: return .orange
        case .high:   return .red
        }
    }
}

enum RepetitionInput: String, CaseIterable, Identifiable {
    case once
    case daily
    case weekly

    var id: String { self.rawValue }
}

private struct PriorityColor: View {
    //associates a color with a priority and shows it on task card
    let priority: PriorityInput
    var body: some View {
        let color: Color = switch priority {
        case .low:  .green
        case .medium:  .orange
        case .high: .red
        }
        Text(priority.rawValue.uppercased())
            .font(.caption2).bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.14))
            .foregroundStyle(color)
            .clipShape(Capsule())
            .accessibilityLabel("Priority \(priority.rawValue)")
    }
}



#Preview {
    AddChoreView()
}
