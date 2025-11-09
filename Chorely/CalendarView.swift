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
        VStack {
            Text("Calendar")
                .font(.largeTitle)
                .padding(.bottom, 20)
                .fontWeight(.bold)
                
            // ColorPicker
            LabeledContent("Calendar Color") {
                ColorPicker("", selection: $color, supportsOpacity: false)
            }
            .fontWeight(.semibold)
            .padding(.horizontal)
            .padding(.bottom, 5)
            
            // HEADER (shows month and year)
            // This replaces the DatePicker
            CalendarHeaderView(date: $date)
            
            
            // --- Existing Weekday Headers ---
            HStack {
                ForEach(daysOfWeek.indices, id: \.self) { index in
                Text(daysOfWeek[index])
                        .fontWeight(.black)
                        .foregroundStyle(color) // @State color used here
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 5)
            
            
            // Calendar Grid
            LazyVGrid(columns: columns) {
                ForEach(days, id: \.self) { day in
                    
                    // --- Pre-calculate date states ---
                    let isToday = day.startOfDay == Date.now.startOfDay
                    let isSelected = day.startOfDay == selectedDate?.startOfDay
                    let isCurrentMonth = day.monthInt == date.monthInt

                    if !isCurrentMonth {
                        // This creates an empty, invisible placeholder
                        Text("")
                            .frame(maxWidth: .infinity, minHeight: 50)
                    } else {
                        // --- This is a tappable day in the current month ---
                        Text(day.formatted(.dateTime.day()))
                            .fontWeight(.bold)
                            // --- Updated Foreground Logic ---
                            // Text is white if it's selected OR today
                            .foregroundStyle(isSelected || isToday ? .white : .secondary)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            // Background uses the @State color
                            .background(
                                Circle()
                                    .foregroundStyle(
                                        // Priority 1: Highlight selected date
                                        isSelected ? color.opacity(0.7) :
                                        // Priority 2: Highlight today's date
                                        isToday ? .red.opacity(1) :
                                        // Priority 3: No highlight
                                        color.opacity(0.2)
                                    )
                            )
                            // Tap gesture
                            .onTapGesture {
                                // Set the selected date to this day
                                selectedDate = day.startOfDay
                            }
                    }
                }
            }
        }
        .padding()
        .onAppear {
            days = date.calendarDisplayDays
        }
        .onChange(of: date) {
            // This logic is correct. When the header changes $date,
            // this triggers and rebuilds the 'days' array.
            days = date.calendarDisplayDays
        }
        Spacer()
    }
}

// Helper view
// A reusable header for the calendar
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
                .foregroundColor(.blue) // Feel free to change this color
            
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
    
    // Formatter for displaying current month and year
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
}


#Preview {
    CalendarView()
}
