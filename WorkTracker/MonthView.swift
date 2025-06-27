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
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total de horas: \(String(format: "%.1f", workMonth.totalHours))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Horas pagas: \(String(format: "%.1f", workMonth.totalPaidHours))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
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

            // Add buttons and totals
            VStack(spacing: 12) {
                // Split button (Add Day with dropdown for missing days)
                if !isLastDayOfMonth() {
                    HStack(spacing: 0) {
                        // Main Add Day button
                        Button(action: addNewEntry) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Adicionar Dia")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 19)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .font(.system(size: 12, weight: .medium))
                        }
                        
                        // Dropdown for missing days
                        let missingDays = getMissingDays()
                        Menu {
                            // Missing days section
                            if !missingDays.isEmpty {
                                Divider()
                                
                                Section("Dias Em Falta (\(missingDays.count))") {
                                    ForEach(missingDays, id: \.self) { date in
                                        Button(action: {
                                            addEntryForDate(date)
                                        }) {
                                            HStack {
                                                Image(systemName: "calendar.badge.plus")
                                                Text(formatDateForMenu(date))
                                            }
                                        }
                                    }
                                }
                            } else {
                                Text("Não há dias em falta.")
                            }
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .frame(width: 44, height: 50)
                                .background(Color.accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor.opacity(0.3), lineWidth: 0.5)
                    )
                    .padding(.horizontal)
                } else {
                    /*HStack(spacing: 0) {
                        // Botão para dias em falta
                        let missingDays = getMissingDays()
                        
                        Button(action: {
                            // Adiciona entrada para o primeiro dia em falta
                            if let firstMissingDay = missingDays.first {
                                addEntryForDate(firstMissingDay)
                            }
                        }) {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                if !missingDays.isEmpty {
                                    Text("Adicionar Dia (\(missingDays.count) em falta)")
                                } else {
                                    Text("Não há dias em falta")
                                }
                            }
                            .frame(height: 44)
                            .frame(maxWidth: .infinity)
                            .background(missingDays.isEmpty ? Color.gray : Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .disabled(missingDays.isEmpty)
                        .buttonStyle(PlainButtonStyle())
                    }*/
                    HStack(spacing: 0) {
                        // Menu para selecionar dia em falta
                        let missingDays = getMissingDays()
                        
                        Menu {
                            if !missingDays.isEmpty {
                                ForEach(missingDays, id: \.self) { date in
                                    Button(action: {
                                        addEntryForDate(date)
                                    }) {
                                        HStack {
                                            Image(systemName: "calendar.badge.plus")
                                            Text(formatDateForMenu(date))
                                        }
                                    }
                                }
                            } else {
                                Text("Não há dias em falta")
                            }
                        } label: {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                if !missingDays.isEmpty {
                                    Text("Adicionar Dia (\(missingDays.count) em falta)")
                                } else {
                                    Text("Não há dias em falta")
                                }
                            }
                            .frame(height: 44)
                            .frame(maxWidth: .infinity)
                            .background(missingDays.isEmpty ? Color.gray : Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .disabled(missingDays.isEmpty)
                        .buttonStyle(PlainButtonStyle())
                    }
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor.opacity(0.3), lineWidth: 0.5)
                    )
                    .padding(.horizontal)
                }

                // Dual totals display
                VStack(spacing: 8) {
                    HStack {
                        Text("Total Estimado:")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("€\(String(format: "%.2f", workMonth.totalEstimatedPay(hourlyRate: settings.hourlyRate)))")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Total Atual:")
                            .font(.title2)
                            .bold()
                        Spacer()
                        Text("€\(String(format: "%.2f", workMonth.totalActualPay(hourlyRate: settings.hourlyRate)))")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.green)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .alert("Apagar entrada?", isPresented: $showDeleteAlert) {
            Button("Apagar", role: .destructive) {
                if let entry = entryToDelete {
                    deleteEntry(entry)
                }
            }
            .keyboardShortcut(.return, modifiers: [])
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Queres mesmo apagar esta entrada de trabalho?")
        }
    }
    
    // MARK: - Add New Entry Functions
    
    // Add consecutive day (from second file)
    private func addNewEntry() {
        let nextDate = getNextWorkDay()
        let defaultPeriod = WorkPeriod.defaultPeriod(for: nextDate)
        let newEntry = WorkEntry(day: nextDate, periods: [defaultPeriod])
        workMonth.entries.append(newEntry)
    }
    
    // Add specific missing day (from first file)
    private func addEntryForDate(_ date: Date) {
        let defaultPeriod = WorkPeriod.defaultPeriod(for: date)
        let newEntry = WorkEntry(day: date, periods: [defaultPeriod])
        workMonth.entries.append(newEntry)
    }
    
    // MARK: - Helper Functions
    
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
    
    private func getMissingDays() -> [Date] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: workMonth.month)
        let month = calendar.component(.month, from: workMonth.month)
        
        // Get the range of days in this month
        guard let range = calendar.range(of: .day, in: .month, for: workMonth.month) else {
            return []
        }
        
        // Get all existing entry days for this month
        let existingDays = Set(workMonth.entries.compactMap { entry in
            let entryYear = calendar.component(.year, from: entry.day)
            let entryMonth = calendar.component(.month, from: entry.day)
            let entryDay = calendar.component(.day, from: entry.day)
            
            // Only consider entries from the same month/year
            if entryYear == year && entryMonth == month {
                return entryDay
            }
            return nil
        })
        
        // If we have entries, find gaps between the first and last entry days
        // If no entries, return empty (no missing days to show yet)
        guard !workMonth.entries.isEmpty else {
            return []
        }
        
        let sortedEntries = workMonth.sortedEntries
        guard let firstEntryDay = sortedEntries.first?.day,
              let lastEntryDay = sortedEntries.last?.day else {
            return []
        }
        
        let firstDay = calendar.component(.day, from: firstEntryDay)
        let lastDay = calendar.component(.day, from: lastEntryDay)
        
        var missingDays: [Date] = []
        
        // Find missing days between first and last entry (inclusive)
        for day in firstDay...lastDay {
            if !existingDays.contains(day) {
                var dateComponents = DateComponents()
                dateComponents.year = year
                dateComponents.month = month
                dateComponents.day = day
                
                if let date = calendar.date(from: dateComponents) {
                    missingDays.append(date)
                }
            }
        }
        
        return missingDays.sorted()
    }
    
    private func formatDateForMenu(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_PT")
        formatter.dateFormat = "d 'de' MMMM"
        return formatter.string(from: date)
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
    
    // MARK: - Delete Functions
    
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
}

// Updated EntryRow with checkbox
struct EntryRow: View {
    @Binding var entry: WorkEntry
    let settings: AppSettings
    let onDelete: () -> Void
    @State private var showPeriodEditor = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Date picker
            DatePicker("", selection: $entry.day, displayedComponents: .date)
                .labelsHidden()
                .frame(width: 120)

            // Time periods display/editor
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(entry.periods.enumerated()), id: \.offset) { index, period in
                    HStack(spacing: 8) {
                        Text("Horário \(index + 1):")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)
                        
                        DatePicker("", selection: $entry.periods[index].startTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .frame(width: 80)
                        
                        Text("-")
                            .foregroundColor(.secondary)
                        
                        DatePicker("", selection: $entry.periods[index].endTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .frame(width: 80)
                        
                        if entry.periods.count > 1 {
                            Button(action: {
                                removePeriod(at: index)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // Add period button
                if entry.periods.count < 4 { // Limit to 4 periods per day
                    Button(action: addPeriod) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Adicionar horário")
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    }
                    .buttonStyle(PlainButtonStyle())
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
            
            // Checkbox for payment status
            VStack {
                Text("Pago")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Toggle("", isOn: $entry.isPaid)
                    .toggleStyle(CheckboxToggleStyle())
            }
            .frame(width: 50)
        }
        .contextMenu {
            Button("Adicionar horário") {
                addPeriod()
            }
            .disabled(entry.periods.count >= 4)
            
            Button(entry.isPaid ? "Marcar como não pago" : "Marcar como pago") {
                entry.isPaid.toggle()
            }
            
            Divider()
            
            Button("Apagar", role: .destructive) {
                onDelete()
            }
        }
        .padding(.vertical, 4)
    }
    
    private func addPeriod() {
        let lastPeriod = entry.periods.last ?? WorkPeriod.defaultPeriod(for: entry.day)
        
        // Start new period 1 hour after the last period ends
        let newStartTime = Calendar.current.date(byAdding: .hour, value: 1, to: lastPeriod.endTime) ?? lastPeriod.endTime
        let newEndTime = Calendar.current.date(byAdding: .hour, value: 3, to: newStartTime) ?? newStartTime
        
        let newPeriod = WorkPeriod(
            startTime: newStartTime,
            endTime: newEndTime
        )
        
        entry.periods.append(newPeriod)
    }
    
    private func removePeriod(at index: Int) {
        guard entry.periods.count > 1 && index < entry.periods.count else { return }
        entry.periods.remove(at: index)
    }
}

// Custom checkbox toggle style
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isOn ? .green : .secondary)
                    .font(.system(size: 18))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
