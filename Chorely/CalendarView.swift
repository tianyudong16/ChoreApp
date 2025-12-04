//
//  CalendarView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 10/30/25.
//

import SwiftUI

struct CalendarView: View {
    
    let userID: String
    let userName: String
    
    @StateObject private var viewModel = CalendarViewModel()
    
    @State private var date = Date.now
    @State private var selectedDate: Date? = nil
    @State private var days: [Date] = []
    @State private var showDailyTasks = false
    
    let daysOfWeek = Date.capitalizedFirstLetterOfWeekdays
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack(spacing: 0) {
            CalendarHeaderView(date: $date)
            filterSection
            
            Divider()
                .padding(.bottom, 8)
            
            daysOfWeekHeader
            calendarContent
            
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .padding(.top, 4)
            }
            
            Spacer()
            
            todayChoresButton
            exportChoresButton
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            days = date.calendarDisplayDays
            viewModel.loadData(userID: userID)
        }
        .onChange(of: date) { _, newDate in
            days = newDate.calendarDisplayDays
        }
        .sheet(isPresented: $showDailyTasks) {
            if let selected = selectedDate {
                DailyTasksView(
                    userID: userID,
                    currentUserName: userName,
                    selectedDate: selected,
                    viewModel: viewModel,
                    isSheetPresentation: true
                )
            }
        }
    }
    
    private var filterSection: some View {
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
    }
    
    private var daysOfWeekHeader: some View {
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
    }
    
    private var calendarContent: some View {
        Group {
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading calendar...")
                Spacer()
            } else {
                calendarGrid
            }
        }
    }
    
    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(days, id: \.self) { day in
                let isToday = day.startOfDay == Date.now.startOfDay
                let isSelected = day.startOfDay == selectedDate?.startOfDay
                let isCurrentMonth = day.monthInt == date.monthInt
                
                if !isCurrentMonth {
                    Text("")
                        .frame(maxWidth: .infinity, minHeight: 50)
                } else {
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
    
    private var todayChoresButton: some View {
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
    private var exportChoresButton: some View {
        Button {
            viewModel.exportMyChoresToAppleCalendar()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "calendar.badge.plus")
                Text("Export My Chores")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.accentColor)
            .foregroundStyle(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
    }

}

struct CalendarDayCell: View {
    let day: Date
    let isToday: Bool
    let isSelected: Bool
    let assigneeColors: [Color]
    let hasChores: Bool
    
    var body: some View {
        VStack(spacing: 4) {
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
            
            if hasChores && !assigneeColors.isEmpty {
                HStack(spacing: 2) {
                    ForEach(assigneeColors.prefix(3), id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)
                    }
                    if assigneeColors.count > 3 {
                        Text("+")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                }
            } else {
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

struct CalendarHeaderView: View {
    @Binding var date: Date
    private let calendar = Calendar.current
    
    var body: some View {
        HStack {
            Button(action: { changeMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .padding()
            }
            
            Spacer()
            
            Text(monthYearFormatter.string(from: date))
                .font(.title.bold())
                .foregroundColor(.accentColor)
            
            Spacer()
            
            Button(action: { changeMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .padding()
            }
        }
        .padding(.bottom, 5)
    }
    
    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: date) {
            date = newDate
        }
    }
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
}

#Preview {
    NavigationStack {
        CalendarView(userID: "test", userName: "Test User")
    }
}
