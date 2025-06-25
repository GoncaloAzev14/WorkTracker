/*import SwiftUI

struct MonthView: View {
    @Binding var workMonth: WorkMonth
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        VStack {
            List {
                ForEach($workMonth.entries) { $entry in
                    HStack {
                        DatePicker("", selection: $entry.day, displayedComponents: .date)
                            .labelsHidden()

                        VStack(alignment: .leading) {
                            DatePicker("Início", selection: $entry.startTime, displayedComponents: [.hourAndMinute])
                                .labelsHidden()

                            DatePicker("Fim", selection: $entry.endTime, displayedComponents: [.hourAndMinute])
                                .labelsHidden()
                        }

                        Spacer()

                        Text(String(format: "%.1f €", entry.calculatedPay(hourlyRate: settings.hourlyRate)))
                            .frame(minWidth: 80, alignment: .trailing)
                    }
                }
            }

            // Notas
            TextEditor(text: $workMonth.notes)
                .frame(height: 100)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))

            // Adicionar nova entrada
            if !isLastDayOfMonth() {
                Button("Adicionar dia") {
                    let nextDate: Date
                    
                    if let lastDay = workMonth.entries.sorted(by: { $0.day < $1.day }).last?.day {

                        nextDate = Calendar.current.date(byAdding: .day, value: 1, to: lastDay) ?? workMonth.month
                    } else {
                        let calendar = Calendar.current
                        let year = calendar.component(.year, from: workMonth.month)
                        let month = calendar.component(.month, from: workMonth.month)
                        
                        var components = DateComponents()
                        components.year = year
                        components.month = month
                        components.day = 1
                        
                        nextDate = calendar.date(from: components) ?? workMonth.month
                    }
                    
                    let weekday = Calendar.current.component(.weekday, from: nextDate)
                    let (startHour, startMinute, endHour, endMinute): (Int, Int, Int, Int)
                    
                    if weekday == 2 || weekday == 4 || weekday == 6 {
                        (startHour, startMinute, endHour, endMinute) = (17, 0, 20, 0)
                    } else
                    if weekday == 1 {
                        (startHour, startMinute, endHour, endMinute) = (0, 0, 0, 0)
                    }else {
                        (startHour, startMinute, endHour, endMinute) = (8, 0, 12, 0)
                    }

                    let startTime = Calendar.current.date(bySettingHour: startHour, minute: startMinute, second: 0, of: nextDate)!
                    let endTime = Calendar.current.date(bySettingHour: endHour, minute: endMinute, second: 0, of: nextDate)!

                    workMonth.entries.append(WorkEntry(day: nextDate, startTime: startTime, endTime: endTime))
                }
                .padding()
            }

            // Total
            Text("Total: \(String(format: "%.2f €", workMonth.entries.reduce(0) { $0 + $1.calculatedPay(hourlyRate: settings.hourlyRate) }))")
                .font(.title2)
                .bold()
                .padding(.bottom)
        }
    }
    
    private func isLastDayOfMonth() -> Bool {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: workMonth.month)
        let month = calendar.component(.month, from: workMonth.month)
        
        let range = calendar.range(of: .day, in: .month, for: workMonth.month)
        let lastDayOfMonth = range?.upperBound ?? 1
        
        return workMonth.entries.contains { entry in
            let entryYear = calendar.component(.year, from: entry.day)
            let entryMonth = calendar.component(.month, from: entry.day)
            let entryDay = calendar.component(.day, from: entry.day)
            
            return entryYear == year && entryMonth == month && entryDay == (lastDayOfMonth - 1)
        }
    }
}*/
//v1
/*import SwiftUI

struct MonthView: View {
    @Binding var workMonth: WorkMonth
    @EnvironmentObject var settings: AppSettings
    @State private var showDeleteAlert = false
    @State private var entryToDelete: WorkEntry?

    var body: some View {
        VStack(spacing: 16) {
            // Header with month name and summary
            VStack(spacing: 8) {
                Text(workMonth.name)
                    .font(.title2)
                    .bold()
                
                HStack {
                    Text("Total de horas: \(String(format: "%.1f", workMonth.totalHours))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Taxa: €\(String(format: "%.2f", settings.hourlyRate))/h")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            
            // Entries list
            List {
                ForEach($workMonth.entries.sorted(by: { $0.wrappedValue.day < $1.wrappedValue.day }), id: \.id) { $entry in
                    EntryRow(entry: $entry, settings: settings) {
                        // Delete action
                        entryToDelete = entry
                        showDeleteAlert = true
                    }
                }
                .onDelete(perform: deleteEntries)
            }
            .listStyle(PlainListStyle())

            // Notes section
            VStack(alignment: .leading, spacing: 8) {
                Text("Notas:")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                TextEditor(text: $workMonth.notes)
                    .frame(height: 100)
                    .padding(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.secondary, lineWidth: 1)
                    )
            }
            .padding(.horizontal)

            // Add button and total
            VStack(spacing: 12) {
                if !isLastDayOfMonth() {
                    Button(action: addNewEntry) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Adicionar Dia")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }

                // Total pay
                Text("Total: €\(String(format: "%.2f", workMonth.totalPay(hourlyRate: settings.hourlyRate)))")
                    .font(.title2)
                    .bold()
                    .padding(.bottom)
            }
        }
        .alert("Apagar entrada?", isPresented: $showDeleteAlert) {
            Button("Apagar", role: .destructive) {
                if let entry = entryToDelete {
                    deleteEntry(entry)
                }
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Queres mesmo apagar esta entrada de trabalho?")
        }
    }
    
    private func addNewEntry() {
        let nextDate = getNextWorkDay()
        let (startHour, startMinute, endHour, endMinute) = getDefaultHours(for: nextDate)
        
        let startTime = Calendar.current.date(bySettingHour: startHour, minute: startMinute, second: 0, of: nextDate) ?? nextDate
        let endTime = Calendar.current.date(bySettingHour: endHour, minute: endMinute, second: 0, of: nextDate) ?? nextDate
        
        let newEntry = WorkEntry(day: nextDate, startTime: startTime, endTime: endTime)
        workMonth.entries.append(newEntry)
    }
    
    private func getNextWorkDay() -> Date {
        if let lastDay = workMonth.sortedEntries.last?.day {
            return Calendar.current.date(byAdding: .day, value: 1, to: lastDay) ?? workMonth.month
        } else {
            // First entry - start with day 1 of the month
            let calendar = Calendar.current
            let year = calendar.component(.year, from: workMonth.month)
            let month = calendar.component(.month, from: workMonth.month)
            
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = 1
            
            return calendar.date(from: components) ?? workMonth.month
        }
    }
    
    private func getDefaultHours(for date: Date) -> (Int, Int, Int, Int) {
        let weekday = Calendar.current.component(.weekday, date)
        
        // Sunday = 1, Monday = 2, ..., Saturday = 7
        switch weekday {
        case 2, 4, 6: // Monday, Wednesday, Friday
            return (17, 0, 20, 0) // 5 PM to 8 PM
        case 1: // Sunday
            return (0, 0, 0, 0) // No work
        default: // Tuesday, Thursday, Saturday
            return (8, 0, 12, 0) // 8 AM to 12 PM
        }
    }
    
    private func deleteEntries(offsets: IndexSet) {
        let sortedEntries = workMonth.sortedEntries
        for index in offsets {
            if index < sortedEntries.count {
                let entryToDelete = sortedEntries[index]
                deleteEntry(entryToDelete)
            }
        }
    }
    
    private func deleteEntry(_ entry: WorkEntry) {
        workMonth.entries.removeAll { $0.id == entry.id }
    }
    
    private func isLastDayOfMonth() -> Bool {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: workMonth.month)
        let month = calendar.component(.month, from: workMonth.month)
        
        guard let range = calendar.range(of: .day, in: .month, for: workMonth.month) else {
            return false
        }
        
        let lastDayOfMonth = range.upperBound - 1
        
        return workMonth.entries.contains { entry in
            let entryYear = calendar.component(.year, from: entry.day)
            let entryMonth = calendar.component(.month, from: entry.day)
            let entryDay = calendar.component(.day, from: entry.day)
            
            return entryYear == year && entryMonth == month && entryDay == lastDayOfMonth
        }
    }
}

// Separate view for each entry row for better organization
struct EntryRow: View {
    @Binding var entry: WorkEntry
    let settings: AppSettings
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Date picker
            DatePicker("", selection: $entry.day, displayedComponents: .date)
                .labelsHidden()
                .frame(width: 120)

            // Time pickers
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Início:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $entry.startTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                
                HStack {
                    Text("Fim:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $entry.endTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            }

            Spacer()
            
            // Hours and pay info
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(String(format: "%.1f", entry.workedHours))h")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("€\(String(format: "%.2f", entry.calculatedPay(hourlyRate: settings.hourlyRate)))")
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(entry.isValid ? .primary : .red)
            }
            .frame(minWidth: 60)
        }
        .contextMenu {
            Button("Apagar", role: .destructive) {
                onDelete()
            }
        }
        .padding(.vertical, 4)
    }
}
*/
import SwiftUI

struct MonthView: View {
    @Binding var workMonth: WorkMonth
    @EnvironmentObject var settings: AppSettings
    @State private var showDeleteAlert = false
    @State private var entryToDelete: WorkEntry?

    var body: some View {
        VStack(spacing: 16) {
            // Header with month name and summary
            VStack(spacing: 8) {
                Text(workMonth.name)
                    .font(.title2)
                    .bold()
                
                HStack {
                    Text("Total de horas: \(String(format: "%.1f", workMonth.totalHours))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Taxa: €\(String(format: "%.2f", settings.hourlyRate))/h")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            
            // Entries list
            List {
                ForEach($workMonth.entries.sorted(by: { $0.wrappedValue.day < $1.wrappedValue.day }), id: \.id) { $entry in
                    EntryRow(entry: $entry, settings: settings) {
                        // Delete action
                        entryToDelete = entry
                        showDeleteAlert = true
                    }
                }
                .onDelete(perform: deleteEntries)
            }
            .listStyle(PlainListStyle())

            // Notes section
            VStack(alignment: .leading, spacing: 8) {
                Text("Notas:")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                TextEditor(text: $workMonth.notes)
                    .frame(height: 100)
                    .padding(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.secondary, lineWidth: 1)
                    )
            }
            .padding(.horizontal)

            // Add button and total
            VStack(spacing: 12) {
                if !isLastDayOfMonth() {
                    Button(action: addNewEntry) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Adicionar Dia")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }

                // Total pay
                Text("Total: €\(String(format: "%.2f", workMonth.totalPay(hourlyRate: settings.hourlyRate)))")
                    .font(.title2)
                    .bold()
                    .padding(.bottom)
            }
        }
        .alert("Apagar entrada?", isPresented: $showDeleteAlert) {
            Button("Apagar", role: .destructive) {
                if let entry = entryToDelete {
                    deleteEntry(entry)
                }
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Queres mesmo apagar esta entrada de trabalho?")
        }
    }
    
    private func addNewEntry() {
        let nextDate = getNextWorkDay()
        let (startHour, startMinute, endHour, endMinute) = getDefaultHours(for: nextDate)
        
        let startTime = Calendar.current.date(bySettingHour: startHour, minute: startMinute, second: 0, of: nextDate) ?? nextDate
        let endTime = Calendar.current.date(bySettingHour: endHour, minute: endMinute, second: 0, of: nextDate) ?? nextDate
        
        let newEntry = WorkEntry(day: nextDate, startTime: startTime, endTime: endTime)
        workMonth.entries.append(newEntry)
    }
    
    private func getNextWorkDay() -> Date {
        if let lastDay = workMonth.sortedEntries.last?.day {
            return Calendar.current.date(byAdding: .day, value: 1, to: lastDay) ?? workMonth.month
        } else {
            // First entry - start with day 1 of the month
            let calendar = Calendar.current
            let year = calendar.component(.year, from: workMonth.month)
            let month = calendar.component(.month, from: workMonth.month)
            
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = 1
            
            return calendar.date(from: components) ?? workMonth.month
        }
    }
    
    private func getDefaultHours(for date: Date) -> (Int, Int, Int, Int) {
        let weekday = Calendar.current.component(.weekday, from: date)
        
        // Sunday = 1, Monday = 2, ..., Saturday = 7
        switch weekday {
        case 2, 4, 6: // Monday, Wednesday, Friday
            return (17, 0, 20, 0) // 5 PM to 8 PM
        case 1: // Sunday
            return (0, 0, 0, 0) // No work
        default: // Tuesday, Thursday, Saturday
            return (8, 0, 12, 0) // 8 AM to 12 PM
        }
    }
    
    private func deleteEntries(offsets: IndexSet) {
        let sortedEntries = workMonth.sortedEntries
        for index in offsets {
            if index < sortedEntries.count {
                let entryToDelete = sortedEntries[index]
                deleteEntry(entryToDelete)
            }
        }
    }
    
    private func deleteEntry(_ entry: WorkEntry) {
        workMonth.entries.removeAll { $0.id == entry.id }
    }
    
    private func isLastDayOfMonth() -> Bool {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: workMonth.month)
        let month = calendar.component(.month, from: workMonth.month)
        
        guard let range = calendar.range(of: .day, in: .month, for: workMonth.month) else {
            return false
        }
        
        let lastDayOfMonth = range.upperBound - 1
        
        return workMonth.entries.contains { entry in
            let entryYear = calendar.component(.year, from: entry.day)
            let entryMonth = calendar.component(.month, from: entry.day)
            let entryDay = calendar.component(.day, from: entry.day)
            
            return entryYear == year && entryMonth == month && entryDay == lastDayOfMonth
        }
    }
}

// Separate view for each entry row for better organization
struct EntryRow: View {
    @Binding var entry: WorkEntry
    let settings: AppSettings
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Date picker
            DatePicker("", selection: $entry.day, displayedComponents: .date)
                .labelsHidden()
                .frame(width: 120)

            // Time pickers
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Início:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $entry.startTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                
                HStack {
                    Text("Fim:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $entry.endTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            }

            Spacer()
            
            // Hours and pay info
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(String(format: "%.1f", entry.workedHours))h")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("€\(String(format: "%.2f", entry.calculatedPay(hourlyRate: settings.hourlyRate)))")
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(entry.isValid ? .primary : .red)
            }
            .frame(minWidth: 60)
        }
        .contextMenu {
            Button("Apagar", role: .destructive) {
                onDelete()
            }
        }
        .padding(.vertical, 4)
    }
}
