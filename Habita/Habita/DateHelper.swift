//
//  DateHelper.swift
//  Habita
//
//  Created by Hubert on 19/05/2025.
//

import Foundation

class DateHelper {
    static let shared = DateHelper()
    
    private let calendar: Calendar = {
            var cal = Calendar.current
            cal.firstWeekday = 2 // Monday
            return cal
        }()
    private let dateFormatter = DateFormatter()
    
    func getFormattedDate(date: Date, format: String) -> String {
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }
    
    func getDayOfWeek(from date: Date) -> String {
        dateFormatter.dateFormat = "E"
        return dateFormatter.string(from: date)
    }
    
    func getDates(for weekOffset: Int) -> [Date] {
        let now = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let startDate = calendar.date(byAdding: .day, value: weekOffset * 7, to: startOfWeek)!
        
        return (0..<7).map { day in
            calendar.date(byAdding: .day, value: day, to: startDate)!
        }
    }
    
    func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        return calendar.isDate(date1, inSameDayAs: date2)
    }
}
