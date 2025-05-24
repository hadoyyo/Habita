//
//  SummaryView.swift
//  Habita
//
//  Created by Hubert on 19/05/2025.
//

import SwiftUI
import CoreData
import Charts

struct SummaryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Habit.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Habit.createdAt, ascending: false)],
        animation: .default
    ) var habits: FetchedResults<Habit>
    
    @State private var selectedTimeRange: TimeRange = .week
    @State private var weekOffset = 0
    @State private var selectedHabit: Habit?
    @State private var refreshID = UUID()
    
    private let dateHelper = DateHelper.shared
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case overall = "Overall"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if habits.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            timeRangePicker
                            
                            if selectedTimeRange == .overall {
                                overallStatsView
                            } else {
                                timeRangeStatsView
                            }
                            
                            habitSelectionView
                            
                            if let habit = selectedHabit ?? habits.first {
                                habitStatsView(habit: habit)
                            }
                            
                            Spacer()
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        HStack(spacing: 2) {
                            Image("logo")
                                .resizable()
                                .renderingMode(.template)
                                .interpolation(.high)
                                .antialiased(true)
                                .scaledToFit()
                                .frame(width: 25, height: 25)
                                .foregroundColor(.yellow)
                            
                            Text("Habita")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
            .navigationTitle("Statistics")
            .id(refreshID)
            .onAppear {
                updateSelectedHabit()
            }
            .onChange(of: habits.count) {
                updateSelectedHabit()
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
                refreshID = UUID()
                updateSelectedHabit()
            }
        }
    }
    
    private func updateSelectedHabit() {
        if selectedHabit == nil && !habits.isEmpty {
            selectedHabit = habits.first
        } else if let selected = selectedHabit, !habits.contains(selected) {
            selectedHabit = habits.first
        }
    }
    
    private var emptyStateView: some View {
        VStack {
            Image("stats-empty")
                .resizable()
                .scaledToFit()
                .frame(width: 320)
                .padding(.bottom, 30)
            
            Text("No stats to display")
                .font(.title2)
            
            Text("Add habits in the Home tab to see statistics")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offset(y: -50)
    }
    
    private var timeRangePicker: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.bottom)
    }
    
    private var overallStatsView: some View {
        VStack(spacing: 15) {
            Text("📌 Overall Summary")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                StatView(title: "Total Habits", value: "\(habits.count)", icon: "list.bullet", color: .blue)
                StatView(title: "Avg Completion", value: "\(Int(averageCompletionRate()))%", icon: "percent", color: .green)
            }
            
            HStack {
                StatView(title: "Best Streak", value: "\(bestStreak())", icon: "flame.fill", color: .orange)
                StatView(title: "Active Days", value: "\(activeDays())", icon: "calendar", color: .purple)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var timeRangeStatsView: some View {
        VStack(spacing: 10) {
            Text("📌 \(selectedTimeRange.rawValue) Summary")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if selectedTimeRange == .week {
                weekNavigation
            }
            
            if let habit = selectedHabit ?? habits.first {
                let data = chartData(for: habit)
                if data.allSatisfy({ $0 == 0 }) {
                    Text("No data available for selected habit and time range.")
                        .foregroundColor(.gray)
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                } else {
                    Chart {
                        ForEach(data.indices, id: \.self) { index in
                            BarMark(
                                x: .value("Day", chartLabels(for: habit)[index]),
                                y: .value("Value", data[index])
                            )
                            .foregroundStyle(Color.yellow)
                        }
                    }
                    .chartForegroundStyleScale(["Value": .yellow])
                    .frame(height: 200)
                    .padding()
                    
                    Text(selectedTimeRange == .week
                         ? "Shows daily value for the selected week."
                         : "Shows average weekly value over the past month.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var weekNavigation: some View {
        HStack {
            Button(action: { weekOffset -= 1 }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.yellow)
            }
            
            Text(weekRangeText())
                .font(.subheadline)
                .frame(maxWidth: .infinity)
            
            Button(action: { weekOffset += 1 }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.yellow)
            }
        }
        .padding(.vertical, 5)
    }
    
    private var habitSelectionView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(habits) { habit in
                    Button(action: { selectedHabit = habit }) {
                        HStack {
                            Text(habit.emoji ?? "📌")
                            Text(habit.name ?? "Unknown").lineLimit(1)
                        }
                        .padding(8)
                        .background(
                            selectedHabit?.id == habit.id ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.1)
                        )
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedHabit?.id == habit.id ? Color.yellow : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, 5)
        }
    }
    
    private func habitStatsView(habit: Habit) -> some View {
        VStack(spacing: 15) {
            Text("\(habit.emoji ?? "📌") \(habit.name ?? "Unknown")")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                StatView(title: "Current Streak", value: "\(streak(for: habit))", icon: "flame.fill", color: .orange)
                StatView(title: "Completion", value: "\(completionPercentage(for: habit))%", icon: "percent", color: .green)
            }
            
            HStack {
                StatView(title: "Best Streak", value: "\(bestStreak(for: habit))", icon: "trophy.fill", color: .yellow)
                StatView(title: "Total Days", value: "\(totalDays(for: habit))", icon: "calendar", color: .blue)
            }
            
            if let type = HabitType(rawValue: habit.type ?? "") {
                if type == .qualitative {
                    StatView(title: "Total Count", value: "\(totalQuantity(for: habit))", icon: "number", color: .purple)
                } else if type == .scalable {
                    StatView(title: "Avg Rating", value: String(format: "%.1f", averageRating(for: habit)), icon: "star.fill", color: .pink)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private func chartData(for habit: Habit) -> [Double] {
        switch selectedTimeRange {
        case .week:
            return weeklyData(for: habit)
        case .month:
            return monthlyData(for: habit)
        case .overall:
            return []
        }
    }
    
    private func chartLabels(for habit: Habit) -> [String] {
        switch selectedTimeRange {
        case .week:
            return dateHelper.getDates(for: weekOffset).map {
                dateHelper.getFormattedDate(date: $0, format: "E")
            }
        case .month:
            return Array(1...4).map { "Week \($0)" }
        case .overall:
            return []
        }
    }
    
    private func weeklyData(for habit: Habit) -> [Double] {
        let dates = dateHelper.getDates(for: weekOffset)
        let sortedDates = dates.sorted { $0 < $1 }
        return sortedDates.map { date in
            if let record = getRecord(for: habit, date: date) {
                switch HabitType(rawValue: habit.type ?? "") {
                case .quantitative:
                    return record.isCompleted ? 1 : 0
                case .qualitative:
                    return Double(record.quantity)
                case .scalable:
                    return Double(record.scaleValue)
                case .none:
                    return 0
                }
            }
            return 0
        }
    }
    
    private func monthlyData(for habit: Habit) -> [Double] {
        var weeklyAverages = [Double]()
        
        for weekOffset in (0..<4).reversed() {
            let dates = dateHelper.getDates(for: -weekOffset)
            
            let weekData = dates.map { date -> Double in
                if let record = getRecord(for: habit, date: date) {
                    switch HabitType(rawValue: habit.type ?? "") {
                    case .quantitative:
                        return record.isCompleted ? 1 : 0
                    case .qualitative:
                        return Double(record.quantity)
                    case .scalable:
                        return Double(record.scaleValue)
                    case .none:
                        return 0
                    }
                }
                return 0
            }
            
            let validValues = weekData.filter { $0 > 0 }
            let average = validValues.isEmpty ? 0 : validValues.reduce(0, +) / Double(validValues.count)
            weeklyAverages.append(average)
        }
        
        return weeklyAverages
    }
    
    private func getRecord(for habit: Habit, date: Date) -> HabitRecord? {
        guard let records = habit.records as? Set<HabitRecord> else { return nil }
        return records.first { record in
            dateHelper.isSameDay(record.date ?? Date(), date)
        }
    }
    
    private func weekRangeText() -> String {
        let dates = dateHelper.getDates(for: weekOffset)
        guard let first = dates.first, let last = dates.last else { return "" }
        return "\(dateHelper.getFormattedDate(date: first, format: "MMM d")) - \(dateHelper.getFormattedDate(date: last, format: "MMM d"))"
    }
    
    private func averageCompletionRate() -> Double {
        guard !habits.isEmpty else { return 0 }
        let total = habits.reduce(0) { $0 + completionPercentage(for: $1) }
        return Double(total) / Double(habits.count)
    }
    
    private func completionPercentage(for habit: Habit) -> Int {
        guard let records = habit.records as? Set<HabitRecord> else { return 0 }
        guard !records.isEmpty else { return 0 }
        let completedRecords = records.filter { isHabitCompleted(record: $0, habit: habit) }
        return Int(Double(completedRecords.count) / Double(records.count) * 100)
    }
    
    private func streak(for habit: Habit) -> Int {
        guard let frequency = habit.frequency else { return 0 }

        let activeWeekdays = frequency.components(separatedBy: ",").compactMap { Int($0) }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var streakCount = 0
        var currentDate = today
        
        while true {
            let weekday = calendar.component(.weekday, from: currentDate)
            
            if activeWeekdays.contains(weekday) {
                if let record = getRecord(for: habit, date: currentDate) {
                    if isHabitCompleted(record: record, habit: habit) {
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
    
    private func isHabitCompleted(record: HabitRecord, habit: Habit) -> Bool {
        switch HabitType(rawValue: habit.type ?? "") {
        case .quantitative: return record.isCompleted
        case .qualitative: return record.quantity >= habit.targetValue
        case .scalable: return record.scaleValue > 0
        case .none: return false
        }
    }
    
    private func bestStreak() -> Int {
        habits.map { streak(for: $0) }.max() ?? 0
    }
    
    private func bestStreak(for habit: Habit) -> Int {
        guard let records = habit.records as? Set<HabitRecord>,
              let frequency = habit.frequency else { return 0 }
        
        let activeWeekdays = frequency.components(separatedBy: ",").compactMap { Int($0) }
        let calendar = Calendar.current

        let sortedDates = records
            .compactMap { $0.date }
            .map { calendar.startOfDay(for: $0) }
            .sorted()
        
        guard let startDate = sortedDates.first, let endDate = sortedDates.last else { return 0 }
        
        var best = 0
        var currentStreak = 0
        var date = startDate
        
        while date <= endDate {
            let weekday = calendar.component(.weekday, from: date)
            
            if activeWeekdays.contains(weekday) {
                if let record = getRecord(for: habit, date: date), isHabitCompleted(record: record, habit: habit) {
                    currentStreak += 1
                    best = max(best, currentStreak)
                } else {
                    currentStreak = 0
                }
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else { break }
            date = nextDate
        }
        
        return best
    }
    
    private func activeDays() -> Int {
        let allRecords = habits.flatMap { $0.records?.allObjects as? [HabitRecord] ?? [] }
        let uniqueDates: Set<Date> = Set(allRecords.compactMap { record in
            guard let date = record.date else { return nil }
            return Calendar.current.startOfDay(for: date)
        })
        return uniqueDates.count
    }
    
    private func totalDays(for habit: Habit) -> Int {
        return habit.records?.count ?? 0
    }
    
    private func totalQuantity(for habit: Habit) -> Int {
        guard let records = habit.records as? Set<HabitRecord> else { return 0 }
        return Int(records.reduce(0) { $0 + $1.quantity })
    }
    
    private func averageRating(for habit: Habit) -> Double {
        guard let records = habit.records as? Set<HabitRecord>, !records.isEmpty else { return 0 }
        return Double(records.reduce(0) { $0 + $1.scaleValue }) / Double(records.count)
    }
}

struct SummaryView_Previews: PreviewProvider {
    static var previews: some View {
        SummaryView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
