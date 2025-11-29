//
//  CalendarView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 10/30/25.
//
//  Updated to integrate with Firebase and show chore indicators

import SwiftUI

// MARK: - CalendarView
/// Main calendar view showing monthly calendar with chore indicators
/// Tapping a date navigates to DailyTasksView for that date
struct CalendarView: View {
    
    // MARK: - Properties
    
    /// User ID passed from MainTabView
    let userID: String
    
    /// Shared ViewModel for calendar data
    @StateObject private var viewModel = CalendarViewModel()
    
    /// Currently displayed month
    @State private var date = Date.now
    
    /// Currently selected date (tapped by user)
    @State private var selectedDate: Date? = nil
    
    /// Days to display in the calendar grid
    @State private var days: [Date] = []
    
    /// Whether to show the daily tasks sheet
    @State private var showDailyTasks = false
    
    /// Calendar layout constants
    let daysOfWeek = Date.capitalizedFirstLetterOfWeekdays
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: Month Navigation Header
            CalendarHeaderView(date: $date)
            
            // MARK: Filter Chips
            /// Filter by House (all) / Mine / Roommates
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ChoreFilter.allCases) { filter in
                        Button {
                            withAnimation {
                                viewModel.selectedFilter = filter
                            }
                        } label: {
                            Text(filter.rawValue)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    viewModel.selectedFilter == filter
                                    ? Color.accentColor.opacity(0.15)
                                    : Color(.systemGray6)
                                )
                                .foregroundStyle(
                                    viewModel.selectedFilter == filter
                                    ? Color.accentColor
                                    : .primary
                                )
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            
            Divider()
                .padding(.bottom, 8)
            
            // MARK: Days of Week Header
            HStack {
                ForEach(daysOfWeek.indices, id: \.self) { index in
                    Text(daysOfWeek[index])
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // MARK: Calendar Grid
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading calendar...")
                Spacer()
            } else {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(days, id: \.self) { day in
                        let isToday = day.startOfDay == Date.now.startOfDay
                        let isSelected = day.startOfDay == selectedDate?.startOfDay
                        let isCurrentMonth = day.monthInt == date.monthInt
                        
                        if !isCurrentMonth {
                            // Empty cell for days not in current month
                            Text("")
                                .frame(maxWidth: .infinity, minHeight: 50)
                        } else {
                            // Calendar day cell
                            CalendarDayCell(
                                day: day,
                                isToday: isToday,
                                isSelected: isSelected,
                                assigneeColors: viewModel.assigneeColorsForDate(day),
                                hasChores: viewModel.dateHasChores(day)
                            )
                            .onTapGesture {
                                selectedDate = day.startOfDay
                                showDailyTasks = true
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // MARK: Today's Chores Button
            Button {
                selectedDate = Date.now.startOfDay
                showDailyTasks = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Today's Chores")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.accentColor.opacity(0.12))
                .foregroundStyle(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
        // Load data when view appears
        .onAppear {
            days = date.calendarDisplayDays
            viewModel.loadData(userID: userID)
        }
        // Update days when month changes
        .onChange(of: date) { _, newDate in
            days = newDate.calendarDisplayDays
        }
        // Sheet for daily tasks
        // In CalendarView.swift, update the sheet modifier:
        .sheet(isPresented: $showDailyTasks) {
            if let selected = selectedDate {
                DailyTasksView(
                    userID: userID,
                    selectedDate: selected,
                    viewModel: viewModel,
                    isSheetPresentation: true // Add this parameter
                )
            }
        }
    }
}

// MARK: - CalendarDayCell
/// Individual day cell in the calendar grid
/// Shows the day number and colored indicators for chores
struct CalendarDayCell: View {
    let day: Date
    let isToday: Bool
    let isSelected: Bool
    let assigneeColors: [Color]
    let hasChores: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            // Day number
            Text(day.formatted(.dateTime.day()))
                .fontWeight(.bold)
                .foregroundStyle(isSelected || isToday ? .white : .primary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .foregroundStyle(
                            isSelected ? Color.accentColor :
                            isToday ? Color.red.opacity(0.8) :
                            Color.clear
                        )
                )
            
            // Colored dots for assignees
            if hasChores && !assigneeColors.isEmpty {
                HStack(spacing: 2) {
                    // Show up to 3 color dots
                    ForEach(assigneeColors.prefix(3), id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)
                    }
                    // Show "+" if more than 3
                    if assigneeColors.count > 3 {
                        Text("+")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                // Placeholder to maintain consistent height
                Color.clear
                    .frame(height: 6)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(hasChores ? Color(.systemGray6) : Color.clear)
        )
    }
}

// MARK: - CalendarHeaderView
/// Header with month/year display and navigation arrows
struct CalendarHeaderView: View {
    @Binding var date: Date
    private let calendar = Calendar.current
    
    var body: some View {
        HStack {
            // Previous month button
            Button(action: { changeMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .padding()
            }
            
            Spacer()
            
            // Current month and year
            Text(monthYearFormatter.string(from: date))
                .font(.title.bold())
                .foregroundColor(.accentColor)
            
            Spacer()
            
            // Next month button
            Button(action: { changeMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .padding()
            }
        }
        .padding(.bottom, 5)
    }
    
    /// Change displayed month by given value (-1 for previous, +1 for next)
    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: date) {
            date = newDate
        }
    }
    
    /// Formatter for month and year display
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        CalendarView(userID: "test")
    }
}
