//
//  ChoresView.swift
//  Chorely
//
//  Created by Brooke Tanner on 11/11/25.
//
// example UI layout, will replace variables with data


import SwiftUI

public struct ChoresView: View {
    // MARK: - UI state
    @State private var selectedFilter: TaskFilter = .all
    @State private var showFilterSheet = false

    public init() {}

    @Environment(\.dismiss) private var dismiss
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Title and filter button
                HStack {
                    Button {
                        dismiss()    // 👈 takes you back to the previous screen
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                            .padding(.trailing, 4)
                    }

                    Text("Daily Tasks")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Spacer()

                    Button {
                        showFilterSheet = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.horizontal)
                .padding(.top, 8)


                // Filter chores (All / Mine / Unassigned)
                FilterChips(selection: $selectedFilter)
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                Divider()

                // Placeholder cards until data is added
                ScrollView {
                    LazyVStack(spacing: 14) {
                        TaskCard()
                        TaskCard(color: .purple, name: "Bathroom", assignee: "Roommate", priority: .high)
                        TaskCard(color: .teal, name: "Trash", assignee: "Unassigned", priority: .low)
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
        }
    }
}




private enum TaskFilter: String, CaseIterable, Identifiable {
    case all = "All", mine = "Mine", unassigned = "Unassigned"
    var id: String { rawValue }
}

private struct FilterChips: View {
    @Binding var selection: TaskFilter
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TaskFilter.allCases, id: \.self) { f in
                    Button { selection = f } label: {
                        Text(f.rawValue)
                            .font(.subheadline).bold()
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(selection == f ? Color.accentColor.opacity(0.15) : Color(.systemGray6))
                            .foregroundStyle(selection == f ? Color.accentColor : .primary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .accessibilityLabel("Current filter \(selection.rawValue)")
    }
}

private enum Priority: String { case low = "Low", med = "Med", high = "High" }

private struct PriorityTag: View {
    let priority: Priority
    var body: some View {
        let color: Color = switch priority {
        case .low:  .green
        case .med:  .orange
        case .high: .red
        }
        Text(priority.rawValue.uppercased())
            .font(.caption2).bold()
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(color.opacity(0.14))
            .foregroundStyle(color)
            .clipShape(Capsule())
            .accessibilityLabel("Priority \(priority.rawValue)")
    }
}

private struct TaskCard: View {
    var color: Color = .yellow
    var name: String = "Chore Name"
    var assignee: String = "Me"
    var dueLabel: String = "Due Today"
    var priority: Priority = .med

    @State private var isDone = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name).font(.headline)
                    HStack(spacing: 8) {
                        Label(dueLabel, systemImage: "calendar.badge.clock")
                            .font(.caption).foregroundStyle(.secondary)
                        PriorityTag(priority: priority)
                    }
                }
                Spacer()
                VStack(spacing: 6) {
                    Badge(text: "Daily")
                    Badge(text: "End")
                }
            }

            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.25))
                .frame(height: 110)

            // Footer
            HStack {
                Label(assignee, systemImage: "person.fill")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())

                Spacer()

                Button {
                    withAnimation(.snappy) { isDone.toggle() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isDone ? "checkmark.square.fill" : "square")
                        Text("Mark Done")
                    }
                    .font(.subheadline)
                }
                .buttonStyle(.plain)
                .foregroundStyle(isDone ? .green : .primary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.background)
                .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(color.opacity(0.45), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

private struct Badge: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption2).bold()
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Color(.systemGray6))
            .clipShape(Capsule())
    }
}


#Preview {
    ChoresView()
}
