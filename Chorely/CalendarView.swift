//
//  CalendarView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 10/30/25.
//

import SwiftUI

struct CalendarView: View {
    @State private var color: Color = .blue
    @State private var date = Date.now
    @State private var days: [Date] = []
    let daysOfWeek = Date.capitalizedFirstLetterOfWeekdays // calls from the DateAndExtension file. Just an extension of Date
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    var body: some View {
        VStack {
            Text("Calendar")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom)
            
            LabeledContent("Calendar Color") {
                ColorPicker("", selection: $color, supportsOpacity: false)
            }
            LabeledContent("Date/Time") {
                DatePicker("", selection: $date)
            }
            
            
            HStack {
                ForEach(daysOfWeek.indices, id: \.self) { index in
                Text(daysOfWeek[index])
                        .fontWeight(.black)
                        .foregroundStyle(color)
                        .frame(maxWidth: .infinity)
                }
            }
            
            
            LazyVGrid(columns: columns) {
                ForEach(days, id: \.self) { day in
                    if day.monthInt != date.monthInt {
                        Text("")
                    } else {
                        Text(day.formatted(.dateTime.day()))
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(
                                Circle()
                                    .foregroundStyle(
                                        Date.now.startOfDay == day.startOfDay ? .red.opacity(0.3) : color.opacity(0.3)
                                    )
                            )
                    }
                }
            }
        }
        .padding()
        Spacer()
        .onAppear {
            days = date.calendarDisplayDays
        }
        .onChange(of: date) {
            days = date.calendarDisplayDays
        }
        
        
    }
}

#Preview {
    CalendarView()
}
