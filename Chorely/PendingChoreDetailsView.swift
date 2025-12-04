//
//  PendingChoreDetailsView.swift
//  Chorely
//
//  Created by Brooke Tanner on 12/4/25.
// shows more details about a pending chore

import SwiftUI

struct PendingChoreDetailsView: View {
    let chore: Chore
    let proposer: String
    let assignee: String?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    //format for main details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(proposer) wants to add a chore:")
                            .font(.title3.bold())

                        Text(chore.name)
                            .font(.title.bold())

                        if let assignee {
                            Text("Assigned to: \(assignee)")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Assigned to: Unassigned")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 10)

                    Divider()

                    //rest of the details
                    Group {
                        detailRow(label: "Due Date", value: chore.date)
                        detailRow(label: "Day of Week", value: chore.day)
                        detailRow(label: "Priority", value: chore.priorityLevel.capitalized)
                        detailRow(label: "Repeats", value: chore.repetitionTime)
                        detailRow(label: "Time Length", value: "\(chore.timeLength) minutes")
                        detailRow(label: "Description", value: chore.description.isEmpty ? "None" : chore.description)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Chore Details")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    //formatting for each detail row
    private func detailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
        .padding(.vertical, 4)
    }
}
