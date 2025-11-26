//
//  CalendarView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 10/30/25.
//
//  Used a tutorial on Youtube on implementing a calendar view

import SwiftUI

struct CalendarView: View {
    @State private var date = Date.now
    @State private var selectedDate: Date? = nil
    @State private var days: [Date] = []
    @State private var color: Color = .blue
    
    let daysOfWeek = Date.capitalizedFirstLetterOfWeekdays
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack {
            CalendarHeaderView(date: $date)
            
            LabeledContent("Calendar Color") {
                ColorPicker("", selection: $color, supportsOpacity: false)
            }
            .padding(.horizontal)
            .padding(.bottom, 5)
            
            HStack {
                ForEach(daysOfWeek.indices, id: \.self) { index in
                    Text(daysOfWeek[index])
                        .fontWeight(.black)
                        .foregroundStyle(color)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 5)
            
            LazyVGrid(columns: columns) {
                ForEach(days, id: \.self) { day in
                    let isToday = day.startOfDay == Date.now.startOfDay
                    let isSelected = day.startOfDay == selectedDate?.startOfDay
                    let isCurrentMonth = day.monthInt == date.monthInt
                    
                    if !isCurrentMonth {
                        Text("")
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color.clear)
                    } else {
                        Text(day.formatted(.dateTime.day()))
                            .fontWeight(.bold)
                            .foregroundStyle(isSelected || isToday ? .white : .secondary)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(
                                Circle()
                                    .foregroundStyle(
                                        isSelected ? color.opacity(0.8) :
                                        isToday ? .red.opacity(0.8) :
                                        color.opacity(0.3)
                                    )
                            )
                            .onTapGesture {
                                selectedDate = day.startOfDay
                            }
                    }
                }
            }
            
            NavigationLink {
                DailyTasksView()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Today’s Chores")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(color.opacity(0.12))
                .foregroundStyle(color)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 8)
        }
        .padding()
        .onAppear {
            days = date.calendarDisplayDays
        }
        .onChange(of: date) {
            days = date.calendarDisplayDays
        }

        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
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
                .foregroundColor(.blue)
            
            Spacer()
            
            Button(action: { changeMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .padding()
            }
        }
        .padding(.bottom, 10)
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
        CalendarView()
    }
}
