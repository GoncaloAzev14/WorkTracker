import SwiftUI

class PDFDocumentItem: NSObject, UIActivityItemSource {
    private let pdfData: Data
    private let fileName: String
    
    init(pdfData: Data, fileName: String) {
        self.pdfData = pdfData
        self.fileName = fileName
        super.init()
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return pdfData
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return pdfData
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return fileName
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "com.adobe.pdf"
    }
}

// MARK: iOS

#if os(iOS)

import PDFKit

struct MonthView: View {
    @Binding var workMonth: WorkMonth
    @EnvironmentObject var settings: AppSettings
    @State private var showDeleteAlert = false
    @State private var entryToDelete: WorkEntry?
    @State private var showingAddDaySheet = false
    @State private var selectedMissingDay: Date?
    @State private var showPDFPreview: Bool = false
    @State private var generatedPDFData: Data?

    var body: some View {
        VStack(spacing: 2) {
            // Summary header
            summaryHeader
                
            // Entries list
            entriesList
                
            // Bottom summary and actions
            bottomSection
        }
        .navigationTitle(workMonth.name).navigationBarTitleDisplayMode(.inline)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Exportar PDF", action: exportToPDF)
                    
                    Button(action: toggleAllPaymentStatus) {
                        Label(allEntriesArePaid ? "Desmarcar Todos" : "Marcar Todos",
                            systemImage: allEntriesArePaid ? "square" : "checkmark.square")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddDaySheet) {
            AddDaySheet(
                workMonth: $workMonth,
                missingDays: getMissingDays(),
                isPresented: $showingAddDaySheet
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPDFPreview) {
            if let pdfData = generatedPDFData {
                PDFPreviewView(pdfData: pdfData, workMonth: workMonth)
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
    
    // MARK: - View Components
    
    private var summaryHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Total: \(String(format: "%.0f", workMonth.totalHours))h")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .bold()
                    
                    Text("Feitas: \(String(format: "%.0f", workMonth.totalPaidHours))h")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .bold()
                }
                
                Spacer()
                
                Text("Taxa: \(String(format: "%.0f", settings.hourlyRate))€/h")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .bold()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            
            Divider()
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private var entriesList: some View {
        List {
            ForEach($workMonth.entries.sorted(by: { $0.wrappedValue.day < $1.wrappedValue.day }), id: \.id) { $entry in
                EntryRow(entry: $entry, settings: settings) {
                    entryToDelete = entry
                    showDeleteAlert = true
                }
            }
            .onDelete(perform: deleteEntries)
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private var bottomSection: some View {
        VStack(spacing: 16) {
            Divider()
            
            // Payment totals
            VStack(spacing: 8) {
                HStack {
                    Text("Total Estimado:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .bold()
                    Spacer()
                    Text("\(String(format: "%.2f", workMonth.totalEstimatedPay(hourlyRate: settings.hourlyRate)))€")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .bold()
                }
                
                HStack {
                    Text("Total Atual:")
                        .font(.title2)
                        .bold()
                    Spacer()
                    Text("\(String(format: "%.2f", workMonth.totalActualPay(hourlyRate: settings.hourlyRate)))€")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal)
            
            // Add day button - only show if we can actually add days
            if canAddMoreDays() {
                Button(action: {
                    if getMissingDays().isEmpty && !isLastDayOfMonth() {
                        addNewEntry()
                    } else {
                        showingAddDaySheet = true
                    }
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(getAddButtonText())
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            
            // Collapsible notes section
            CollapsibleNotesSection(workMonth: $workMonth)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // MARK: - Helper Functions
    
    private func canAddMoreDays() -> Bool {
        // Can add days if there are missing days OR if we haven't reached the last day of the month
        return !getMissingDays().isEmpty || !isLastDayOfMonth()
    }
    
    private func getAddButtonText() -> String {
        let missingDays = getMissingDays()
        if missingDays.isEmpty && !isLastDayOfMonth() {
            return "Adicionar Próximo Dia"
        } else if !missingDays.isEmpty {
            return "Adicionar Dia (\(missingDays.count) em falta)"
        } else {
            return "Adicionar Dia"
        }
    }
    
    /*private func exportToPDF() {
        guard let pdfData = PDFGenerator.generatePDF(for: workMonth, hourlyRate: settings.hourlyRate) else {
            return
        }
        
        generatedPDFData = pdfData
        showPDFPreview = true
    }*/
    
    private func exportToPDF() {
        guard let pdfData = PDFGenerator.generatePDF(for: workMonth, hourlyRate: settings.hourlyRate) else {
            return
        }
        
        // Create a clean filename with .pdf extension
        let cleanFileName = workMonth.name
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
        
        let fileName = "\(cleanFileName).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try pdfData.write(to: tempURL)
            
            // Create document item with proper metadata
            let documentItem = PDFDocumentItem(pdfData: pdfData, fileName: fileName)
            
            let activityVC = UIActivityViewController(
                activityItems: [tempURL, documentItem],
                applicationActivities: nil
            )
            
            // Configure for better compatibility
            activityVC.setValue(fileName, forKey: "subject")
            
            // Exclude problematic activities that might crash
            activityVC.excludedActivityTypes = [
                .assignToContact,
                .addToReadingList,
                .openInIBooks  // This one often causes issues
            ]
            
            // Present the activity view controller
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController {
                    
                    // Find the topmost view controller
                    var topVC = rootVC
                    while let presentedVC = topVC.presentedViewController {
                        topVC = presentedVC
                    }
                    
                    // For iPad - set popover source
                    if let popover = activityVC.popoverPresentationController {
                        popover.sourceView = topVC.view
                        popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: 100, width: 0, height: 0)
                        popover.permittedArrowDirections = [.up]
                    }
                    
                    topVC.present(activityVC, animated: true)
                }
            }
            
            // Clean up temporary file after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                try? FileManager.default.removeItem(at: tempURL)
            }
            
        } catch {
            print("Failed to create temporary PDF file: \(error)")
            // Show an alert to the user
            DispatchQueue.main.async {
                // You might want to show an alert here
            }
        }
    }

    private func exportToPDFDirect() {
        guard let pdfData = PDFGenerator.generatePDF(for: workMonth, hourlyRate: settings.hourlyRate) else {
            return
        }
        
        let cleanFileName = workMonth.name
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        
        let fileName = "\(cleanFileName).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try pdfData.write(to: tempURL)
            
            // Create document item with proper metadata
            let documentItem = PDFDocumentItem(pdfData: pdfData, fileName: fileName)
            
            let activityVC = UIActivityViewController(
                activityItems: [tempURL, documentItem],
                applicationActivities: nil
            )
            
            // Exclude problematic activities
            activityVC.excludedActivityTypes = [
                .assignToContact,
                .addToReadingList
            ]
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                
                // For iPad - set popover source
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = rootVC.view
                    popover.sourceRect = CGRect(x: window.bounds.midX, y: 100, width: 0, height: 0)
                    popover.permittedArrowDirections = [.up]
                }
                
                rootVC.present(activityVC, animated: true)
            }
        } catch {
            print("Failed to create temporary PDF file: \(error)")
        }
    }
    
    // MARK: - Payment Functions
    
    private func toggleAllPaymentStatus() {
        let newStatus = !allEntriesArePaid
        for index in workMonth.entries.indices {
            workMonth.entries[index].isPaid = newStatus
        }
    }
    
    private var allEntriesArePaid: Bool {
        return !workMonth.entries.isEmpty && workMonth.entries.allSatisfy { $0.isPaid }
    }
    
    // MARK: - Add New Entry Functions
    
    private func addNewEntry() {
        let nextDate = getNextWorkDay()
        // Only add if the next date belongs to the current month
        if dateIsInCurrentMonth(nextDate) {
            let defaultPeriod = WorkPeriod.defaultPeriod(for: nextDate)
            let newEntry = WorkEntry(day: nextDate, periods: [defaultPeriod])
            workMonth.entries.append(newEntry)
        }
    }
    
    private func addEntryForDate(_ date: Date) {
        // Only add if the date belongs to the current month
        if dateIsInCurrentMonth(date) {
            let defaultPeriod = WorkPeriod.defaultPeriod(for: date)
            let newEntry = WorkEntry(day: date, periods: [defaultPeriod])
            workMonth.entries.append(newEntry)
        }
    }
    
    private func dateIsInCurrentMonth(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let dateMonth = calendar.component(.month, from: date)
        let dateYear = calendar.component(.year, from: date)
        let currentMonth = calendar.component(.month, from: workMonth.month)
        let currentYear = calendar.component(.year, from: workMonth.month)
        
        return dateMonth == currentMonth && dateYear == currentYear
    }
    
    private func getNextWorkDay() -> Date {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: workMonth.month)
        let month = calendar.component(.month, from: workMonth.month)
        
        if let lastDay = workMonth.sortedEntries.last?.day {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: lastDay) ?? workMonth.month
            
            // Ensure the next day is still in the current month
            let nextDayMonth = calendar.component(.month, from: nextDay)
            let nextDayYear = calendar.component(.year, from: nextDay)
            
            if nextDayMonth == month && nextDayYear == year {
                return nextDay
            } else {
                // If we've exceeded the month, return the last day of the month
                return getLastDayOfMonth()
            }
        } else {
            // If no entries exist, start with the first day of the month
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = 1
            
            return calendar.date(from: components) ?? workMonth.month
        }
    }
    
    private func getLastDayOfMonth() -> Date {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: workMonth.month)
        let month = calendar.component(.month, from: workMonth.month)
        
        guard let range = calendar.range(of: .day, in: .month, for: workMonth.month) else {
            return workMonth.month
        }
        
        let lastDay = range.upperBound - 1
        
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = lastDay
        
        return calendar.date(from: components) ?? workMonth.month
    }
    
    private func getMissingDays() -> [Date] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: workMonth.month)
        let month = calendar.component(.month, from: workMonth.month)
        
        guard let range = calendar.range(of: .day, in: .month, for: workMonth.month) else {
            return []
        }
        
        let existingDays = Set(workMonth.entries.compactMap { entry in
            let entryYear = calendar.component(.year, from: entry.day)
            let entryMonth = calendar.component(.month, from: entry.day)
            let entryDay = calendar.component(.day, from: entry.day)
            
            if entryYear == year && entryMonth == month {
                return entryDay
            }
            return nil
        })
        
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

// MARK: - Collapsible Notes Section

struct CollapsibleNotesSection: View {
    @Binding var workMonth: WorkMonth
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "note.text")
                        .foregroundColor(workMonth.notes.isEmpty ? .secondary : .accentColor)
                        .font(.system(size: 16))
                    
                    Text("Notas")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if !workMonth.notes.isEmpty && !isExpanded {
                        Text("(\(String(workMonth.notes.prefix(30)))\(workMonth.notes.count > 30 ? "..." : ""))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14, weight: .medium))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.3), value: isExpanded)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(UIColor.systemGroupedBackground))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expandable content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    TextEditor(text: $workMonth.notes)
                        .frame(height: 120)
                        .padding(12)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(UIColor.systemGray4), lineWidth: 1)
                        )
                    
                    if workMonth.notes.isEmpty {
                        HStack {
                            Image(systemName: "pencil")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            Text("Adiciona notas sobre este mês de trabalho...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                        .padding(.horizontal, 4)
                    } else {
                        HStack {
                            Text("\(workMonth.notes.count) caracteres")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("Limpar") {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    workMonth.notes = ""
                                }
                            }
                            .font(.caption2)
                            .foregroundColor(.red)
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}

// MARK: - Add Day Sheet

struct AddDaySheet: View {
    @Binding var workMonth: WorkMonth
    let missingDays: [Date]
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                List {
                    Section {
                        let nextDay = getNextWorkDay()
                        if dateIsInCurrentMonth(nextDay) && !isLastDayOfMonth() {
                            Button(action: {
                                addNextDay()
                                isPresented = false
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Adicionar Próximo Dia")
                                    Spacer()
                                    Text(formatDate(nextDay))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    if !missingDays.isEmpty {
                        Section("Dias Em Falta (\(missingDays.count))") {
                            ForEach(missingDays, id: \.self) { date in
                                Button(action: {
                                    addEntryForDate(date)
                                    isPresented = false
                                }) {
                                    HStack {
                                        Image(systemName: "calendar.badge.plus")
                                            .foregroundColor(.blue)
                                        Text(formatDate(date))
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Adicionar Dia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancelar") {
                        isPresented = false
                    }
                }
            }
        }
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
    
    private func addNextDay() {
        let nextDate = getNextWorkDay()
        if dateIsInCurrentMonth(nextDate) {
            let defaultPeriod = WorkPeriod.defaultPeriod(for: nextDate)
            let newEntry = WorkEntry(day: nextDate, periods: [defaultPeriod])
            workMonth.entries.append(newEntry)
        }
    }
    
    private func addEntryForDate(_ date: Date) {
        if dateIsInCurrentMonth(date) {
            let defaultPeriod = WorkPeriod.defaultPeriod(for: date)
            let newEntry = WorkEntry(day: date, periods: [defaultPeriod])
            workMonth.entries.append(newEntry)
        }
    }
    
    private func dateIsInCurrentMonth(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let dateMonth = calendar.component(.month, from: date)
        let dateYear = calendar.component(.year, from: date)
        let currentMonth = calendar.component(.month, from: workMonth.month)
        let currentYear = calendar.component(.year, from: workMonth.month)
        
        return dateMonth == currentMonth && dateYear == currentYear
    }
    
    private func getNextWorkDay() -> Date {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: workMonth.month)
        let month = calendar.component(.month, from: workMonth.month)
        
        if let lastDay = workMonth.sortedEntries.last?.day {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: lastDay) ?? workMonth.month
            
            // Ensure the next day is still in the current month
            let nextDayMonth = calendar.component(.month, from: nextDay)
            let nextDayYear = calendar.component(.year, from: nextDay)
            
            if nextDayMonth == month && nextDayYear == year {
                return nextDay
            } else {
                // If we've exceeded the month, return the last day of the month
                return getLastDayOfMonth()
            }
        } else {
            // If no entries exist, start with the first day of the month
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = 1
            
            return calendar.date(from: components) ?? workMonth.month
        }
    }
    
    private func getLastDayOfMonth() -> Date {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: workMonth.month)
        let month = calendar.component(.month, from: workMonth.month)
        
        guard let range = calendar.range(of: .day, in: .month, for: workMonth.month) else {
            return workMonth.month
        }
        
        let lastDay = range.upperBound - 1
        
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = lastDay
        
        return calendar.date(from: components) ?? workMonth.month
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_PT")
        formatter.dateFormat = "d 'de' MMMM"
        return formatter.string(from: date)
    }
}

// MARK: - EntryRow

/*struct EntryRow: View {
    @Binding var entry: WorkEntry
    let settings: AppSettings
    let onDelete: () -> Void
    @State private var showingPeriodEditor = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Header row with date and payment status
            HStack {
                // Display date as text instead of DatePicker to prevent editing
                Text(formatEntryDate(entry.day))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(String(format: "%.1f", entry.workedHours))h")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("€\(String(format: "%.2f", entry.calculatedPay(hourlyRate: settings.hourlyRate)))")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(entry.isValid ? .primary : .red)
                }
                
                Toggle("", isOn: $entry.isPaid)
                    .toggleStyle(CheckboxToggleStyle())
            }
            
            // Time periods
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(entry.periods.enumerated()), id: \.offset) { index, period in
                    HStack(spacing: 12) {
                        Text("Horário \(index + 1):")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 70, alignment: .leading)
                        
                        DatePicker("", selection: $entry.periods[index].startTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .datePickerStyle(CompactDatePickerStyle())
                        
                        Text("-")
                            .foregroundColor(.secondary)
                        
                        DatePicker("", selection: $entry.periods[index].endTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .datePickerStyle(CompactDatePickerStyle())
                        
                        if entry.periods.count > 1 {
                            Button(action: {
                                removePeriod(at: index)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 20))
                            }
                        }
                    }
                }
                
                if entry.periods.count < 4 {
                    Button(action: addPeriod) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Adicionar horário")
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Apagar", role: .destructive) {
                onDelete()
            }
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
    }
    
    private func formatEntryDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_PT")
        formatter.dateFormat = "d 'de' MMMM"
        return formatter.string(from: date)
    }
    
    private func addPeriod() {
        let lastPeriod = entry.periods.last ?? WorkPeriod.defaultPeriod(for: entry.day)
        
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

// MARK: - Checkbox Toggle Style

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .green : .secondary)
                .font(.system(size: 22))
        }
        .buttonStyle(PlainButtonStyle())
    }
}*/
// MARK: - Checkbox Toggle Style

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .green : .secondary)
                .font(.system(size: 22))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Entry Row

struct EntryRow: View {
    @Binding var entry: WorkEntry
    let settings: AppSettings
    let onDelete: () -> Void
    @State private var showingPeriodEditor = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Header row with date and payment status
            HStack {
                // Display date as text instead of DatePicker to prevent editing
                Text(formatEntryDate(entry.day))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(String(format: "%.1f", entry.workedHours))h")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("€\(String(format: "%.2f", entry.calculatedPay(hourlyRate: settings.hourlyRate)))")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(entry.isValid ? .primary : .red)
                }
                
                Toggle("", isOn: $entry.isPaid)
                    .toggleStyle(CheckboxToggleStyle())
            }
            
            // Time periods
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(entry.periods.enumerated()), id: \.offset) { index, period in
                    HStack(spacing: 12) {
                        Text("Horário \(index + 1):")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 70, alignment: .leading)
                        
                        DatePicker("", selection: Binding(
                            get: { entry.periods[index].startTime },
                            set: { newValue in
                                if index < entry.periods.count {
                                    entry.periods[index].startTime = newValue
                                }
                            }
                        ), displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .datePickerStyle(CompactDatePickerStyle())
                        
                        Text("-")
                            .foregroundColor(.secondary)
                        
                        DatePicker("", selection: Binding(
                            get: { entry.periods[index].endTime },
                            set: { newValue in
                                if index < entry.periods.count {
                                    entry.periods[index].endTime = newValue
                                }
                            }
                        ), displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .datePickerStyle(CompactDatePickerStyle())
                        
                        if entry.periods.count > 1 {
                            Button(action: {
                                removePeriod(at: index)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 20))
                            }
                            .buttonStyle(BorderlessButtonStyle()) // This prevents the button from expanding
                        }
                    }
                }
                
                if entry.periods.count < 4 {
                    Button(action: addPeriod) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Adicionar horário")
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    }
                    .buttonStyle(BorderlessButtonStyle()) // This prevents the button from expanding
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle()) // This prevents the entire row from acting as a button
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Apagar", role: .destructive) {
                onDelete()
            }
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
    }
    
    private func formatEntryDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_PT")
        formatter.dateFormat = "d 'de' MMMM"
        return formatter.string(from: date)
    }
    
    private func addPeriod() {
        guard entry.periods.count < 4 else { return }
        
        let calendar = Calendar.current
        let baseDate = entry.day
        
        // Get the last period's end time or use a default
        let lastEndTime = entry.periods.last?.endTime ?? calendar.date(bySettingHour: 9, minute: 0, second: 0, of: baseDate)!
        
        // Create new period starting 1 hour after the last one ended
        let newStartHour = calendar.component(.hour, from: lastEndTime) + 1
        let newStartMinute = calendar.component(.minute, from: lastEndTime)
        
        let newStartTime = calendar.date(bySettingHour: newStartHour, minute: newStartMinute, second: 0, of: baseDate) ?? lastEndTime
        let newEndTime = calendar.date(byAdding: .hour, value: 3, to: newStartTime) ?? newStartTime
        
        let newPeriod = WorkPeriod(
            startTime: newStartTime,
            endTime: newEndTime
        )
        
        entry.periods.append(newPeriod)
    }
    
    private func removePeriod(at index: Int) {
        guard entry.periods.count > 1 && index >= 0 && index < entry.periods.count else {
            return
        }
        entry.periods.remove(at: index)
    }
}
#endif

// MARK: MacOS

#if os(macOS)
import SwiftUI

struct MonthView: View {
    @Binding var workMonth: WorkMonth
    @EnvironmentObject var settings: AppSettings
    @State private var showDeleteAlert = false
    @State private var entryToDelete: WorkEntry?
    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 16) {
            // Header with month name and summary
            VStack(spacing: 8) {
                /*Text(workMonth.name)
                    .font(.title2)
                    .bold()
                */
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total: \(String(format: "%.0f", workMonth.totalHours))h")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Feitas: \(String(format: "%.0f", workMonth.totalPaidHours))h")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("Taxa: \(String(format: "%.0f", settings.hourlyRate))€/h")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 15)
            }
            
            // Table header with master checkbox
            if !workMonth.entries.isEmpty {
                HStack(spacing: 12) {
                    // Date column header
                    Text("Data")
                        //.font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(width: 120, alignment: .leading)
                        .padding(.leading, 40)
                        .bold()
                    
                    // Time periods column header
                    Text("Horários")
                        //.font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 50)
                        .bold()
                    
                    // Hours and pay column header
                    Text("Horas/Valor")
                        //.font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(minWidth: 60, alignment: .trailing)
                        .padding(.trailing, 27)
                        .bold()
                    
                    // Master checkbox column
                    VStack(spacing: 30) {
                        /*Text("Pago")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)*/
                        
                        Toggle("", isOn: Binding(
                            get: { allEntriesArePaid },
                            set: { _ in toggleAllPaymentStatus() }
                        ))
                        .toggleStyle(CheckboxToggleStyle())
                    }
                    .padding(.trailing, 7)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
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

            // Dual totals display
            VStack(spacing: 8) {
                HStack {
                    Text("Total Estimado:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .bold()
                    Spacer()
                    Text("\(String(format: "%.2f", workMonth.totalEstimatedPay(hourlyRate: settings.hourlyRate)))€")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .bold()
                }
                
                HStack {
                    Text("Total Atual:")
                        .font(.title2)
                        .bold()
                    Spacer()
                    Text("\(String(format: "%.2f", workMonth.totalActualPay(hourlyRate: settings.hourlyRate)))€")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal)
            //.padding(.bottom)
            
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
                            .padding(.vertical, 17)
                            .background(isHovering ? Color.accentColor.opacity(200/255) : Color.accentColor)
                            .foregroundColor(.white)
                            .font(.system(size: 12, weight: .medium))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .animation(.easeInOut(duration: 0.2), value: isHovering)
                        .onHover { hovering in
                            isHovering = hovering
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
                                .frame(width: 44)
                                .frame(maxHeight: .infinity)
                                .background(isHovering ? Color.accentColor.opacity(200/255) : Color.accentColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .animation(.easeInOut(duration: 0.2), value: isHovering)
                        .onHover { hovering in
                            isHovering = hovering
                        }
                    }
                    .frame(height: 50)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal)
                } else {
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
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .background(
                            missingDays.isEmpty
                                ? Color.gray.opacity(200/255)
                                : (isHovering ? Color.accentColor.opacity(200/255) : Color.accentColor)
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(missingDays.isEmpty)
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    .animation(.easeInOut(duration: 0.2), value: isHovering)
                    .onHover { hovering in
                        isHovering = hovering
                    }
                }
                
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(height: 2)
                    .padding(.vertical, 8)
                
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
                .padding(.bottom, 20)
                
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
    
    // MARK: - Payment Functions
    
    private func toggleAllPaymentStatus() {
        let newStatus = !allEntriesArePaid
        for index in workMonth.entries.indices {
            workMonth.entries[index].isPaid = newStatus
        }
    }
    
    private var allEntriesArePaid: Bool {
        return !workMonth.entries.isEmpty && workMonth.entries.allSatisfy { $0.isPaid }
    }
    
    private var unpaidEntriesCount: Int {
        return workMonth.entries.filter { !$0.isPaid }.count
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
            /*DatePicker("", selection: $entry.day, displayedComponents: .date)
                .labelsHidden()
                .frame(width: 120)*/
            Text(entry.day, style: .date)
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
                
                Text("\(String(format: "%.2f", entry.calculatedPay(hourlyRate: settings.hourlyRate)))€")
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(entry.isValid ? .primary : .red)
            }
            .frame(minWidth: 60)
            
            // Checkbox for payment status
            VStack {
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
#endif
