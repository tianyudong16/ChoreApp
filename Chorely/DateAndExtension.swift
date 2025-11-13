//
//  DateAndExtension.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/8/25.
//

//
//  DateAndExtension.swift
//  Chorely
//

import Foundation

extension Date {
    
    /// Returns all days of the month for this date
    func extractMonthDates() -> [Date] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: self))!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        
        return range.compactMap { day -> Date? in
            return calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }
    
    /// Month name + year (e.g., "January 2025")
    func monthYearString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: self)
    }
    
    /// Returns true if this date is today
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
    
    /// Returns the first weekday index (1 = Sunday, 2 = Monday...)
    func firstWeekdayOfMonth() -> Int {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: self))!
        return calendar.component(.weekday, from: startOfMonth)
    }
}
