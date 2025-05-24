//
//  HabitDetailView.swift
//  Habita
//
//  Created by Hubert on 19/05/2025.
//

import SwiftUI
import CoreData

struct HabitDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var habit: Habit
    let selectedDate: Date
    @State private var showingDeleteAlert = false
    @State private var showingEditView = false
    @State private var refreshID = UUID()
    
    private let dateHelper = DateHelper.shared
    private let daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    habitHeader
                    
                    if let type = HabitType(rawValue: habit.type ?? "") {
                        switch type {
                        case .quantitative:
                            quantitativeView
                        case .qualitative:
                            qualitativeView
                        case .scalable:
                            scalableView
                        }
                    }
                    
                    statsView
                    
                    calendarView
                    
                    Spacer()
                }
                .padding()
                .id(refreshID)
            }
            .navigationTitle("Habit Details")
            .navigationBarItems(trailing: HStack {
                Button(action: { showingEditView = true }) {
                    Image(systemName: "pencil")
                    .foregroundColor(.yellow)
                }
                
                Button(action: { showingDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            })
            .alert(isPresented: $showingDeleteAlert) {
                Alert(
                    title: Text("Delete Habit?"),
                    message: Text("Are you sure you want to delete this habit? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        deleteHabit()
                    },
                    secondaryButton: .cancel()
                )
            }
            .sheet(isPresented: $showingEditView) {
                AddHabitView(habitToEdit: habit)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
    
    private var habitHeader: some View {
        VStack {
            Text(habit.emoji ?? "📌")
                .font(.system(size: 50))
            
            Text(habit.name ?? "Unknown Habit")
                .font(.title)
                .fontWeight(.bold)
            
            if let type = HabitType(rawValue: habit.type ?? "") {
                Text(type.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom, 8)
            }
            
            Text(dateHelper.getFormattedDate(date: selectedDate, format: "EEEE, MMM d"))
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    private var quantitativeView: some View {
        VStack(spacing: 16) {
            Text("Did you complete this habit?")
                .font(.headline)
                .padding(.bottom, 4)
            
            if isHabitActive(for: selectedDate) {
                HStack(spacing: 20) {
                    Button(action: {
                        updateRecord(isCompleted: true)
                        refreshID = UUID()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.green)
                            
                            Text("Completed")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        .frame(width: 120, height: 100)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(getRecord(for: selectedDate)?.isCompleted == true ? Color.green : Color.clear, lineWidth: 2)
                        )
                    }
                    
                    Button(action: {
                        updateRecord(isCompleted: false)
                        refreshID = UUID()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.red)
                            
                            Text("Not Done")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        .frame(width: 120, height: 100)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(getRecord(for: selectedDate)?.isCompleted == false ? Color.red : Color.clear, lineWidth: 2)
                        )
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                if let record = getRecord(for: selectedDate) {
                    Text(record.isCompleted ? "Great job! Keep it up!" : "No worries, keep trying!")
                        .font(.subheadline)
                        .foregroundColor(record.isCompleted ? .green : .red)
                        .padding(.top, 8)
                }
            } else {
                Text("This habit isn't scheduled for this day")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.vertical, 20)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(15)
        .padding(.horizontal, 8)
    }
    
    private var qualitativeView: some View {
        VStack {
            Text("Count for \(dateHelper.getFormattedDate(date: selectedDate, format: "MMM d"))")
                .font(.headline)
            
            if isHabitActive(for: selectedDate) {
                Stepper(value: Binding(
                    get: { getRecord(for: selectedDate)?.quantity ?? 0 },
                    set: {
                        updateRecord(quantity: $0)
                        refreshID = UUID()
                    }
                ), in: 0...habit.targetValue) {
                    Text("\(getRecord(for: selectedDate)?.quantity ?? 0)/\(habit.targetValue)")
                        .font(.title)
                }
                
                if let record = getRecord(for: selectedDate), record.quantity >= habit.targetValue {
                    Text("Goal achieved!")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .padding(.top, 5)
                }
            } else {
                Text("Not scheduled for this day")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var scalableView: some View {
        VStack {
            Text("Rating for \(dateHelper.getFormattedDate(date: selectedDate, format: "MMM d"))")
                .font(.headline)
            
            if isHabitActive(for: selectedDate) {
                if let scaleRange = Int(habit.scaleRange ?? "10") {
                    Stepper(value: Binding(
                        get: { getRecord(for: selectedDate)?.scaleValue ?? 0 },
                        set: {
                            updateRecord(scaleValue: $0)
                            refreshID = UUID()
                        }
                    ), in: 0...Int16(scaleRange)) {
                        Text("\(getRecord(for: selectedDate)?.scaleValue ?? 0)/\(scaleRange)")
                            .font(.title)
                    }
                }
            } else {
                Text("Not scheduled for this day")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var statsView: some View {
        VStack {
            HStack {
                StatView(title: "Current Streak", value: "\(streak())", icon: "flame.fill", color: .orange)
                StatView(title: "Completion", value: "\(completionPercentage())%", icon: "percent", color: .blue)
            }
            
            Text("Progress Chart")
                .font(.headline)
                .padding(.top)
            
            RoundedRectangle(cornerRadius: 5)
                .frame(height: 20)
                .foregroundColor(.gray.opacity(0.2))
                .overlay(
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 5)
                            .frame(width: geometry.size.width * CGFloat(completionPercentage()) / 100)
                            .foregroundColor(.yellow)
                    }
                )
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var calendarView: some View {
        VStack {
            Text("Calendar")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(String(day.prefix(1)))
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
            }

            let dates = getLast30Days()
            let firstDate = dates.first ?? Date()
            let weekdayOffset = ((Calendar.current.component(.weekday, from: firstDate) + 5) % 7)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                ForEach(0..<weekdayOffset, id: \.self) { _ in
                    Circle()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.clear)
                }

                ForEach(dates, id: \.self) { date in
                    if let record = getRecord(for: date) {
                        let status: HabitStatus = {
                            switch HabitType(rawValue: habit.type ?? "") {
                            case .quantitative:
                                return record.isCompleted ? .completed : .failed
                            case .qualitative:
                                return record.quantity >= habit.targetValue ? .completed : .failed
                            case .scalable:
                                return record.scaleValue > 0 ? .completed : .failed
                            case .none:
                                return .notTracked
                            }
                        }()
                        
                        Circle()
                            .frame(width: 20, height: 20)
                            .foregroundColor(status.color)
                    } else {
                        Circle()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.clear)
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }

    private func getRecord(for date: Date) -> HabitRecord? {
        guard let records = habit.records as? Set<HabitRecord> else { return nil }
        return records.first { record in
            dateHelper.isSameDay(record.date ?? Date(), date)
        }
    }
    
    private func updateRecord(isCompleted: Bool? = nil, quantity: Int16? = nil, scaleValue: Int16? = nil) {
           var record = getRecord(for: selectedDate)
           
           if record == nil {
               record = HabitRecord(context: viewContext)
               record?.date = selectedDate
               record?.habit = habit
           }
           
           if let isCompleted = isCompleted {
               record?.isCompleted = isCompleted
           }
           
           if let quantity = quantity {
               record?.quantity = quantity
           }
           
           if let scaleValue = scaleValue {
               record?.scaleValue = scaleValue
           }
           
           do {
               try viewContext.save()
               refreshID = UUID()
           } catch {
               print("Failed to save record: \(error)")
           }
       }
    
    private func isHabitActive(for date: Date) -> Bool {
        guard let frequency = habit.frequency else { return false }
        let weekday = Calendar.current.component(.weekday, from: date)
        return frequency.contains(String(weekday))
    }
    
    private func streak() -> Int {
        guard let frequency = habit.frequency else { return 0 }
        
        let activeWeekdays = frequency.components(separatedBy: ",").compactMap { Int($0) }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streakCount = 0
        var currentDate = today
        
        while true {
            let weekday = calendar.component(.weekday, from: currentDate)
            
            if activeWeekdays.contains(weekday) {
                if let record = getRecord(for: currentDate) {
                    if isHabitCompleted(record: record) {
                        streakCount += 1
                    } else {
                        break
                    }
                } else {
                    if calendar.compare(currentDate, to: today, toGranularity: .day) == .orderedAscending {
                        break
                    }
                }
            }
            
            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
            currentDate = previousDate
        }
        
        return streakCount
    }

    
    private func isHabitCompleted(record: HabitRecord) -> Bool {
        switch HabitType(rawValue: habit.type ?? "") {
        case .quantitative: return record.isCompleted
        case .qualitative: return record.quantity >= habit.targetValue
        case .scalable: return record.scaleValue > 0
        case .none: return false
        }
    }
    
    private func completionPercentage() -> Int {
        guard let records = habit.records as? Set<HabitRecord> else { return 0 }
        guard !records.isEmpty else { return 0 }
        
        let completedRecords = records.filter { record in
            switch HabitType(rawValue: habit.type ?? "") {
            case .quantitative: return record.isCompleted
            case .qualitative: return record.quantity >= habit.targetValue
            case .scalable: return record.scaleValue > 0
            case .none: return false
            }
        }
        
        return Int(Double(completedRecords.count) / Double(records.count) * 100)
    }
    
    private func getLast30Days() -> [Date] {
        var dates = [Date]()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        for i in (0..<30).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                dates.append(date)
            }
        }
        return dates
    }
    
    private func deleteHabit() {
        viewContext.delete(habit)
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Failed to delete habit: \(error)")
        }
    }
}

enum HabitStatus {
    case completed
    case failed
    case notTracked
    
    var color: Color {
        switch self {
        case .completed: return .green
        case .failed: return .red
        case .notTracked: return .gray.opacity(0.3)
        }
    }
}

struct StatView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct HabitDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let habit = Habit(context: context)
        habit.name = "Running"
        habit.emoji = "🏃‍♂️"
        habit.type = "Quantitative"
        habit.frequency = "1,2,3,4,5"
        habit.createdAt = Date()
        
        return HabitDetailView(habit: habit, selectedDate: Date())
            .environment(\.managedObjectContext, context)
    }
}
