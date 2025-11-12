//
//  CalendarView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 10/30/25.
//

import SwiftUI

struct CalendarView: View {
    @State private var date = Date.now // This controls the MONTH being viewed
    @State private var selectedDate: Date? = nil // This stores the DAY the user taps
    @State private var days: [Date] = []
    
    // This color will be set by the ColorPicker
    @State private var color: Color = .blue
    
    let daysOfWeek = Date.capitalizedFirstLetterOfWeekdays // calls from the DateAndExtension file
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        NavigationView{
            VStack {
                
                CalendarHeaderView(date: $date)
                
                // The ColorPicker is right below the header for easy access
                LabeledContent("Calendar Color") {
                    ColorPicker("", selection: $color, supportsOpacity: false)
                }
                .padding(.horizontal) // Add some padding to match the calendar
                .padding(.bottom, 5)   // Add a little space below it
                
                
                // Weekday Headers
                // This will update its color when the picker changes
                HStack {
                    ForEach(daysOfWeek.indices, id: \.self) { index in
                        Text(daysOfWeek[index])
                            .fontWeight(.black)
                            .foregroundStyle(color) // Uses the @State color
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.bottom, 5)
                
                
                // --- Calendar Grid ---
                LazyVGrid(columns: columns) {
                    ForEach(days, id: \.self) { day in
                        
                        // Pre-calculate date states
                        let isToday = day.startOfDay == Date.now.startOfDay
                        let isSelected = day.startOfDay == selectedDate?.startOfDay
                        let isCurrentMonth = day.monthInt == date.monthInt
                        
                        if !isCurrentMonth {
                            // This creates an empty, invisible placeholder
                            Text("")
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(Color.clear) // Keep non-month days blank
                        } else {
                            // This is a tappable day in the current month
                            Text(day.formatted(.dateTime.day()))
                                .fontWeight(.bold)
                            // Text is white if it's selected OR today
                                .foregroundStyle(isSelected || isToday ? .white : .secondary)
                                .frame(maxWidth: .infinity, minHeight: 50)
                            // Background uses the @State color
                                .background(
                                    Circle()
                                        .foregroundStyle(
                                            // Priority 1: Highlight selected date (strong)
                                            isSelected ? color.opacity(0.8) :
                                                
                                                // Priority 2: Highlight today's date (strong, contrasting)
                                            isToday ? .red.opacity(0.8) :
                                                
                                                // Priority 3: Default faint circle for all other days
                                            color.opacity(0.3)
                                        )
                                )
                                .onTapGesture {
                                    // Set the selected date to this day
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
                    .background(.blue.opacity(0.12))
                    .foregroundStyle(.blue)
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
}

// HELPER VIEW for the header
struct CalendarHeaderView: View {
    @Binding var date: Date
    private let calendar = Calendar.current
    
    var body: some View {
        HStack {
            // "Previous Month" Button
            Button(action: {
                changeMonth(by: -1)
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .padding()
            }
            
            Spacer()
            
            // Month and Year Title
            Text(monthYearFormatter.string(from: date))
                .font(.title.bold())
                .foregroundColor(.blue)
            
            Spacer()
            
            // "Next Month" Button
            Button(action: {
                changeMonth(by: 1)
            }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .padding()
            }
        }
        .padding(.bottom, 10)
    
    }
    
    // Helper function to change the current month
    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: date) {
            date = newDate
        }
    }
    
    // Formatter for displaying "November 2025"
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
}


#Preview {
    CalendarView()
}
