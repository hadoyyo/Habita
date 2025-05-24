//
//  HomeView.swift
//  Habita
//
//  Created by Hubert on 19/05/2025.
//

import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Habit.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Habit.createdAt, ascending: true)]
    ) var habits: FetchedResults<Habit>
    
    @State private var showingAddHabit = false
    @State private var weekOffset = 0
    @State private var selectedDate = Date()
    @State private var showingHabitDetail: Habit? = nil
    @State private var refreshID = UUID()
    
    private let dateHelper = DateHelper.shared
    
    var body: some View {
        NavigationView {
            VStack {
                dateScrollView
                
                if habitsForSelectedDate.isEmpty {
                    emptyStateView
                } else {
                    habitsListView
                }
                
                Spacer()
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    addButton
                }
            }
            .navigationTitle("Home")
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(item: $showingHabitDetail) { habit in
                HabitDetailView(habit: habit, selectedDate: selectedDate)
                    .environment(\.managedObjectContext, viewContext)
                    .onDisappear {
                        refreshID = UUID()
                    }
            }
            .id(refreshID)
        }
    }
    private var dateScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(getAvailableDates(), id: \.self) { date in
                    VStack {
                        Text(dateHelper.getFormattedDate(date: date, format: "dd"))
                            .font(.system(size: 18, weight: .bold))
                        Text(dateHelper.getDayOfWeek(from: date))
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .frame(width: 50, height: 60)
                    .background(dateHelper.isSameDay(date, selectedDate) ? Color.yellow : Color.gray.opacity(0.2))
                    .foregroundColor(dateHelper.isSameDay(date, selectedDate) ? .white : .primary)
                    .cornerRadius(10)
                    .onTapGesture {
                        selectedDate = date
                    }
                }
            }
            .padding()
        }
    }
    
    private var habitsListView: some View {
        List {
            ForEach(habitsForSelectedDate) { habit in
                habitRow(habit: habit)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deleteHabit(habit: habit)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        Button {
                            showingHabitDetail = habit
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            deleteHabit(habit: habit)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
    }
    
    private func habitRow(habit: Habit) -> some View {
        HStack {
            Text(habit.emoji ?? "📌")
                .font(.system(size: 24))
                .padding(.trailing, 8)
            
            VStack(alignment: .leading) {
                Text(habit.name ?? "Unknown Habit")
                    .font(.headline)
                
                if let type = HabitType(rawValue: habit.type ?? "") {
                    Text(type.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            if let record = getRecord(for: habit, date: selectedDate) {
                switch HabitType(rawValue: habit.type ?? "") {
                case .quantitative:
                    Image(systemName: record.isCompleted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(record.isCompleted ? .green : .red)
                    
                case .qualitative:
                    VStack(alignment: .trailing) {
                        Text("\(record.quantity)/\(habit.targetValue)")
                            .font(.subheadline)
                        ProgressView(value: Double(record.quantity), total: Double(habit.targetValue))
                            .frame(width: 50)
                    }
                    
                case .scalable:
                    VStack(alignment: .trailing) {
                        Text("\(record.scaleValue)/\(habit.scaleRange ?? "10")")
                            .font(.subheadline)
                        if let maxValue = Int(habit.scaleRange ?? "10"), maxValue > 0 {
                            ProgressView(value: Double(record.scaleValue), total: Double(maxValue))
                                .frame(width: 50)
                        }
                    }
                    
                case .none:
                    EmptyView()
                }
            } else {
                Image(systemName: "questionmark.circle")
                    .foregroundColor(.gray)
            }
            
            if streak(for: habit) > 0 {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("\(streak(for: habit))")
                    .font(.caption)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isHabitActive(for: habit, date: selectedDate) {
                showingHabitDetail = habit
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack {
            Image("habit-empty")
                .resizable()
                .scaledToFit()
                .frame(width: 320)
                .padding(.bottom, 30)
            
            Text("No habits for this day")
                .font(.title2)
            Text("Tap the + button to add a new habit")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offset(y: -50)
    }
    
    private var addButton: some View {
        Button {
            showingAddHabit = true
        } label: {
            Image(systemName: "plus")
                .foregroundColor(.yellow)
                .fontWeight(.bold)
        }
    }
    
    private func getAvailableDates() -> [Date] {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            var dates = [Date]()
            
            for i in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                    dates.append(date)
                }
            }
            return dates.reversed()
        }
    
    private var habitsForSelectedDate: [Habit] {
        habits.filter { habit in
            guard let frequency = habit.frequency else { return false }
            let weekday = Calendar.current.component(.weekday, from: selectedDate)
            return frequency.contains(String(weekday))
        }
    }
    
    private func getRecord(for habit: Habit, date: Date) -> HabitRecord? {
        guard let records = habit.records as? Set<HabitRecord> else { return nil }
        return records.first { record in
            dateHelper.isSameDay(record.date ?? Date(), date)
        }
    }
    
    private func isHabitActive(for habit: Habit, date: Date) -> Bool {
        guard let frequency = habit.frequency else { return false }
        let weekday = Calendar.current.component(.weekday, from: date)
        return frequency.contains(String(weekday))
    }
    
    private func isHabitCompleted(record: HabitRecord, habit: Habit) -> Bool {
        switch HabitType(rawValue: habit.type ?? "") {
        case .quantitative: return record.isCompleted
        case .qualitative: return record.quantity >= habit.targetValue
        case .scalable: return record.scaleValue > 0
        case .none: return false
        }
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
                    let isPastDay = calendar.compare(currentDate, to: today, toGranularity: .day) == .orderedAscending
                    if isPastDay {
                        break
                    }
                }
            }
            
            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDate
        }
        
        return streakCount
    }

    
    private func deleteHabit(habit: Habit) {
        withAnimation {
            viewContext.delete(habit)
            do {
                try viewContext.save()
                refreshID = UUID()
            } catch {
                print("Failed to delete habit: \(error)")
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
