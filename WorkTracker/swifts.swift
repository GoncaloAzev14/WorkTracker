import Foundation
import SwiftUI

class AppSettings: ObservableObject {
    @AppStorage("hourlyRate") var hourlyRate: Double = 5.0
}
---
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var months: [WorkMonth] = []
    @State private var showRenameSheet = false
    @State private var selectedMonthForRename: WorkMonth?
    @State private var renameText: String = ""
    @State private var showDeleteConfirmation = false
    @State private var monthToDelete: WorkMonth?
    @State private var selectedMonthID: WorkMonth.ID? = nil
    @State private var showNewSheetDialog = false
    @State private var newSheetName = ""
    @State private var selectedMonthNumber = Calendar.current.component(.month, from: Date())
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var showSettings = false
    
    private let dataManager = DataManager()

    var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Meses")
                        .font(.title2)
                        .bold()
                        .padding(.bottom, 10)
                    Spacer()
                    Text("\(months.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .background(.secondary.opacity(0.2))
                        .clipShape(Capsule())
                        .padding(.bottom, 10)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // List of months
                List(months.sorted(by: { $0.month > $1.month }), selection: $selectedMonthID) { month in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(month.name.isEmpty ? "Sem Título" : month.name)
                            .font(.subheadline)
                            .lineLimit(1)
                        
                        HStack {
                            Text(month.monthName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if month.hasContent {
                                VStack(alignment: .trailing, spacing: 2) {
                                    // Show actual pay (green) and estimated pay (gray) if different
                                    let actualPay = month.totalActualPay(hourlyRate: settings.hourlyRate)
                                    let estimatedPay = month.totalEstimatedPay(hourlyRate: settings.hourlyRate)
                                    
                                    if actualPay > 0 {
                                        Text("€\(String(format: "%.0f", actualPay))")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                            .bold()
                                    }
                                    
                                    if actualPay != estimatedPay {
                                        Text("€\(String(format: "%.0f", estimatedPay))")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                    .tag(month.id)
                    .contextMenu {
                        Button("Renomear") {
                            selectedMonthForRename = month
                            renameText = month.name
                            showRenameSheet = true
                        }
                        
                        Button("Duplicar") {
                            duplicateMonth(month)
                        }
                        
                        Divider()
                        
                        Button("Apagar", role: .destructive) {
                            if month.hasContent {
                                monthToDelete = month
                                showDeleteConfirmation = true
                            } else {
                                deleteMonth(month)
                            }
                        }
                    }
                }
                .listStyle(SidebarListStyle())
                
                Spacer()
                
                // Bottom buttons
                VStack(spacing: 12) {
                    Button(action: {
                        newSheetName = ""
                        selectedMonthNumber = Calendar.current.component(.month, from: Date())
                        selectedYear = Calendar.current.component(.year, from: Date())
                        showNewSheetDialog = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Nova Folha")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        showSettings = true
                    }) {
                        Label("Definições", systemImage: "gearshape")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .alert("Apagar folha?", isPresented: $showDeleteConfirmation, presenting: monthToDelete) { month in
                Button("Apagar", role: .destructive) {
                    deleteMonth(month)
                    monthToDelete = nil
                }
                .keyboardShortcut(.return, modifiers: [])
                Button("Cancelar", role: .cancel) {
                    monthToDelete = nil
                }
            } message: { month in
                Text("A folha \"\(month.name)\" contém dados. Queres mesmo apagá-la?")
            }
        } detail: {
            // Detail view
            if let selectedMonthID = selectedMonthID,
               let selectedMonth = months.first(where: { $0.id == selectedMonthID }) {
                MonthView(workMonth: binding(for: selectedMonth))
            } else {
                // Placeholder view
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("Seleciona uma folha")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Escolhe uma folha da lista para começar a registar o teu trabalho")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showNewSheetDialog) {
            NewSheetView(
                newSheetName: $newSheetName,
                selectedMonthNumber: $selectedMonthNumber,
                selectedYear: $selectedYear,
                isPresented: $showNewSheetDialog,
                onCreate: createNewSheet
            )
        }
        .sheet(isPresented: $showRenameSheet) {
            RenameSheetView(
                renameText: $renameText,
                isPresented: $showRenameSheet,
                onSave: saveRename
            )
        }
        .onAppear {
            loadData()
        }
        .onChange(of: months) { _, _ in
            saveData()
        }
    }
    
    // MARK: - Data Management
    private func loadData() {
        months = dataManager.loadMonths()
    }
    
    private func saveData() {
        dataManager.saveMonths(months)
    }
    
    // MARK: - Month Management
    private func createNewSheet() {
        let trimmedName = newSheetName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let finalName = trimmedName.isEmpty ?
            "\(monthName(for: selectedMonthNumber)) \(selectedYear)" :
            trimmedName
        
        var dateComponents = DateComponents()
        dateComponents.year = selectedYear
        dateComponents.month = selectedMonthNumber
        dateComponents.day = 1
        let monthDate = Calendar.current.date(from: dateComponents) ?? Date()
        
        let newMonth = WorkMonth(
            month: monthDate,
            entries: [],
            notes: "",
            name: finalName
        )
        
        months.append(newMonth)
        selectedMonthID = newMonth.id
        showNewSheetDialog = false
    }
    
    private func duplicateMonth(_ month: WorkMonth) {
        let duplicatedMonth = WorkMonth(
            month: month.month,
            entries: month.entries,
            notes: month.notes,
            name: "\(month.name) (Cópia)"
        )
        months.append(duplicatedMonth)
        selectedMonthID = duplicatedMonth.id
    }
    
    private func deleteMonth(_ month: WorkMonth) {
        if selectedMonthID == month.id {
            selectedMonthID = nil
        }
        months.removeAll { $0.id == month.id }
        selectedMonthForRename = nil
    }
    
    private func saveRename() {
        if let selected = selectedMonthForRename,
           let index = months.firstIndex(where: { $0.id == selected.id }) {
            months[index].name = renameText
        }
        showRenameSheet = false
    }
    
    // MARK: - Helpers
    private func binding(for month: WorkMonth) -> Binding<WorkMonth> {
        guard let index = months.firstIndex(where: { $0.id == month.id }) else {
            fatalError("Month not found")
        }
        return $months[index]
    }
    
    private func monthName(for month: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_PT")
        return formatter.monthSymbols[month - 1].capitalized
    }
}

// MARK: - Supporting Views
struct NewSheetView: View {
    @Binding var newSheetName: String
    @Binding var selectedMonthNumber: Int
    @Binding var selectedYear: Int
    @Binding var isPresented: Bool
    let onCreate: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Nova Folha")
                .font(.title2)
                .bold()

            TextField("Nome da folha (opcional)", text: $newSheetName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit(onCreate)

            VStack(alignment: .leading, spacing: 12) {
                Text("Período:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Picker("Mês", selection: $selectedMonthNumber) {
                        ForEach(1...12, id: \.self) { month in
                            Text(monthName(for: month))
                                .tag(month)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Picker("Ano", selection: $selectedYear) {
                        ForEach(2020...2030, id: \.self) { year in
                            Text(String(year))
                                .tag(year)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }

            HStack(spacing: 20) {
                Button("Cancelar") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                
                Button("Criar") {
                    onCreate()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top)
        }
        .padding(24)
        .frame(minWidth: 400)
    }
    
    private func monthName(for month: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_PT")
        return formatter.monthSymbols[month - 1].capitalized
    }
}

struct RenameSheetView: View {
    @Binding var renameText: String
    @Binding var isPresented: Bool
    let onSave: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Renomear Folha")
                .font(.title2)
                .bold()

            TextField("Novo nome", text: $renameText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit(onSave)

            HStack(spacing: 20) {
                Button("Cancelar") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                
                Button("Guardar") {
                    onSave()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(minWidth: 350)
    }
}

// MARK: - Data Manager
class DataManager {
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private var dataURL: URL {
        documentsDirectory.appendingPathComponent("WorkMonths.json")
    }
    
    func saveMonths(_ months: [WorkMonth]) {
        do {
            let data = try JSONEncoder().encode(months)
            try data.write(to: dataURL)
        } catch {
            print("Failed to save months: \(error)")
        }
    }
    
    func loadMonths() -> [WorkMonth] {
        do {
            let data = try Data(contentsOf: dataURL)
            return try JSONDecoder().decode([WorkMonth].self, from: data)
        } catch {
            print("Failed to load months: \(error)")
            // Try to load from old format if new format fails
            return loadLegacyMonths() ?? []
        }
    }
    
    // Legacy support for old WorkEntry format (single startTime/endTime)
    private func loadLegacyMonths() -> [WorkMonth]? {
        struct LegacyWorkEntry: Codable {
            let id: UUID
            var day: Date
            var startTime: Date
            var endTime: Date
        }
        
        struct LegacyWorkMonth: Codable {
            let id: UUID
            var month: Date
            var entries: [LegacyWorkEntry]
            var notes: String
            var name: String
        }
        
        do {
            let data = try Data(contentsOf: dataURL)
            let legacyMonths = try JSONDecoder().decode([LegacyWorkMonth].self, from: data)
            
            // Convert to new format
            let convertedMonths = legacyMonths.map { legacyMonth in
                let convertedEntries = legacyMonth.entries.map { legacyEntry in
                    let period = WorkPeriod(startTime: legacyEntry.startTime, endTime: legacyEntry.endTime)
                    return WorkEntry(day: legacyEntry.day, periods: [period])
                }
                
                return WorkMonth(
                    month: legacyMonth.month,
                    entries: convertedEntries,
                    notes: legacyMonth.notes,
                    name: legacyMonth.name
                )
            }
            
            // Save in new format
            saveMonths(convertedMonths)
            return convertedMonths
            
        } catch {
            print("Failed to load legacy months: \(error)")
            return nil
        }
    }
}
---
import Foundation

struct WorkPeriod: Identifiable, Codable, Equatable {
    let id = UUID()
    var startTime: Date
    var endTime: Date
    
    var workedHours: Double {
        guard endTime > startTime else { return 0 }
        return endTime.timeIntervalSince(startTime) / 3600
    }
    
    var isValid: Bool {
        return endTime > startTime
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: startTime))-\(formatter.string(from: endTime))"
    }
}

struct WorkEntry: Identifiable, Codable, Equatable {
    let id = UUID()
    var day: Date
    var periods: [WorkPeriod]
    var isPaid: Bool = false  // New property for checkbox state
    
    var workedHours: Double {
        return periods.reduce(0) { $0 + $1.workedHours }
    }

    func calculatedPay(hourlyRate: Double) -> Double {
        return workedHours * hourlyRate
    }
    
    var isValid: Bool {
        return !periods.isEmpty && periods.allSatisfy { $0.isValid }
    }
    
    var isEmpty: Bool {
        return periods.isEmpty
    }
    
    // Helper to get formatted time periods string
    var timePeriodsString: String {
        return periods.map { $0.timeString }.joined(separator: " | ")
    }
    
    // Initialize with default periods for convenience
    init(day: Date, periods: [WorkPeriod] = [], isPaid: Bool = false) {
        self.day = day
        self.periods = periods.isEmpty ? [WorkPeriod.defaultPeriod(for: day)] : periods
        self.isPaid = isPaid
    }
}

extension WorkPeriod {
    static func defaultPeriod(for date: Date) -> WorkPeriod {
        let weekday = Calendar.current.component(.weekday, from: date)
        let (startHour, startMinute, endHour, endMinute): (Int, Int, Int, Int)
        
        switch weekday {
        case 2, 4, 6: // Monday, Wednesday, Friday
            (startHour, startMinute, endHour, endMinute) = (17, 0, 20, 0)
        case 1: // Sunday
            (startHour, startMinute, endHour, endMinute) = (0, 0, 0, 0)
        default: // Tuesday, Thursday, Saturday
            (startHour, startMinute, endHour, endMinute) = (8, 0, 12, 0)
        }
        
        let startTime = Calendar.current.date(bySettingHour: startHour, minute: startMinute, second: 0, of: date) ?? date
        let endTime = Calendar.current.date(bySettingHour: endHour, minute: endMinute, second: 0, of: date) ?? date
        
        return WorkPeriod(startTime: startTime, endTime: endTime)
    }
}

struct WorkMonth: Identifiable, Codable, Equatable {
    let id = UUID()
    var month: Date
    var entries: [WorkEntry]
    var notes: String
    var name: String

    // Total estimated pay (all entries)
    func totalEstimatedPay(hourlyRate: Double) -> Double {
        return entries.reduce(0) { $0 + $1.calculatedPay(hourlyRate: hourlyRate) }
    }
    
    // Total actual pay (only checked entries)
    func totalActualPay(hourlyRate: Double) -> Double {
        return entries.filter { $0.isPaid }.reduce(0) { $0 + $1.calculatedPay(hourlyRate: hourlyRate) }
    }
    
    // Legacy method for backward compatibility
    func totalPay(hourlyRate: Double) -> Double {
        return totalEstimatedPay(hourlyRate: hourlyRate)
    }
    
    var totalHours: Double {
        return entries.reduce(0) { $0 + $1.workedHours }
    }
    
    // Total hours for paid entries only
    var totalPaidHours: Double {
        return entries.filter { $0.isPaid }.reduce(0) { $0 + $1.workedHours }
    }

    var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_PT")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: month)
    }
    
    // Helper to get entries sorted by date
    var sortedEntries: [WorkEntry] {
        return entries.sorted { $0.day < $1.day }
    }
    
    // Helper to check if month has content
    var hasContent: Bool {
        return !entries.isEmpty || !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
---
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
                activityItems: [tempURL],
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
---
//
//  PDFGenerator1.swift
//  WorkTracker
//
//  Created by Gonçalo Azevedo on 31/07/2025.
//

import SwiftUI
import PDFKit

// MARK: - PDF Generator
class PDFGenerator {
    static func generatePDF(for workMonth: WorkMonth, hourlyRate: Double) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Work Tracker",
            kCGPDFContextTitle: workMonth.name
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            drawPDFContent(context: context, workMonth: workMonth, hourlyRate: hourlyRate, pageRect: pageRect)
        }
        
        return data
    }
    
    private static func drawPDFContent(context: UIGraphicsPDFRendererContext, workMonth: WorkMonth, hourlyRate: Double, pageRect: CGRect) {
        let margin: CGFloat = 50
        let sortedEntries = workMonth.sortedEntries
        var currentEntryIndex = 0
        var isFirstPage = true
        
        while currentEntryIndex < sortedEntries.count {
            // Begin new page
            context.beginPage()
            let cgContext = context.cgContext
            
            var yPosition: CGFloat = margin
            
            // Draw header on every page
            yPosition = drawHeader(cgContext: cgContext, workMonth: workMonth, hourlyRate: hourlyRate, pageRect: pageRect, yPosition: yPosition, isFirstPage: isFirstPage)
            
            // Draw table header
            yPosition = drawTableHeader(cgContext: cgContext, pageRect: pageRect, yPosition: yPosition)
            let tableStartY = yPosition - 25
            
            // Draw entries for this page
            let entriesDrawn = drawEntries(
                cgContext: cgContext,
                entries: sortedEntries,
                startIndex: currentEntryIndex,
                hourlyRate: hourlyRate,
                pageRect: pageRect,
                yPosition: &yPosition,
                tableStartY: tableStartY
            )
            
            // Draw table borders
            drawTableBorders(cgContext: cgContext, pageRect: pageRect, tableStartY: tableStartY, yPosition: yPosition)
            
            // Draw footer
            drawFooter(cgContext: cgContext, pageRect: pageRect)
            
            // Update index for next page
            currentEntryIndex += entriesDrawn
            isFirstPage = false
            
            // If we've drawn all entries, add notes to the last page if there's space
            if currentEntryIndex >= sortedEntries.count {
                drawNotes(cgContext: cgContext, workMonth: workMonth, pageRect: pageRect, yPosition: &yPosition)
            }
        }
    }
    
    // MARK: - Drawing Helper Functions
    
    private static func drawHeader(cgContext: CGContext, workMonth: WorkMonth, hourlyRate: Double, pageRect: CGRect, yPosition: CGFloat, isFirstPage: Bool) -> CGFloat {
        let margin: CGFloat = 50
        var currentY = yPosition
        
        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.black
        ]
        
        let title = workMonth.name
        title.draw(at: CGPoint(x: margin, y: currentY), withAttributes: titleAttributes)
        currentY += 40
        
        // Month info
        let monthAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.gray
        ]
        
        workMonth.monthName.draw(at: CGPoint(x: margin, y: currentY), withAttributes: monthAttributes)
        currentY += 30
        
        // Summary section (only on first page)
        if isFirstPage {
            currentY = drawSummary(cgContext: cgContext, workMonth: workMonth, hourlyRate: hourlyRate, pageRect: pageRect, yPosition: currentY)
        }
        
        return currentY
    }
    
    private static func drawSummary(cgContext: CGContext, workMonth: WorkMonth, hourlyRate: Double, pageRect: CGRect, yPosition: CGFloat) -> CGFloat {
        let margin: CGFloat = 50
        var currentY = yPosition
        
        let summaryAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor.black
        ]
        
        let regularAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        
        // Draw summary box
        let summaryRect = CGRect(x: margin, y: currentY, width: pageRect.width - 2*margin, height: 100)
        cgContext.setStrokeColor(UIColor.lightGray.cgColor)
        cgContext.setLineWidth(1)
        cgContext.stroke(summaryRect)
        
        currentY += 15
        
        // Summary content
        "Resumo".draw(at: CGPoint(x: margin + 10, y: currentY), withAttributes: summaryAttributes)
        currentY += 20
        
        let totalHours = String(format: "Total de Horas: %.1f", workMonth.totalHours)
        totalHours.draw(at: CGPoint(x: margin + 10, y: currentY), withAttributes: regularAttributes)
        
        let paidHours = String(format: "Horas Pagas: %.1f", workMonth.totalPaidHours)
        paidHours.draw(at: CGPoint(x: margin + 200, y: currentY), withAttributes: regularAttributes)
        currentY += 15
        
        let hourlyRateText = String(format: "Taxa Horária: €%.2f", hourlyRate)
        hourlyRateText.draw(at: CGPoint(x: margin + 10, y: currentY), withAttributes: regularAttributes)
        
        let totalPay = String(format: "Total Pago: €%.2f", workMonth.totalActualPay(hourlyRate: hourlyRate))
        totalPay.draw(at: CGPoint(x: margin + 200, y: currentY), withAttributes: regularAttributes)
        currentY += 15
        
        let estimatedPay = String(format: "Total Estimado: €%.2f", workMonth.totalEstimatedPay(hourlyRate: hourlyRate))
        estimatedPay.draw(at: CGPoint(x: margin + 10, y: currentY), withAttributes: regularAttributes)
        currentY += 35
        
        return currentY
    }
    
    private static func drawTableHeader(cgContext: CGContext, pageRect: CGRect, yPosition: CGFloat) -> CGFloat {
        let margin: CGFloat = 50
        var currentY = yPosition
        
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        
        // Calculate column widths
        let dateColumnWidth: CGFloat = 80
        let timeColumnWidth: CGFloat = 280
        let hoursColumnWidth: CGFloat = 60
        let payColumnWidth: CGFloat = 70
        
        // Draw table header background
        let headerRect = CGRect(x: margin, y: currentY, width: pageRect.width - 2*margin, height: 25)
        cgContext.setFillColor(UIColor.systemGray5.cgColor)
        cgContext.fill(headerRect)
        
        currentY += 5
        
        "Data".draw(at: CGPoint(x: margin + 5, y: currentY), withAttributes: headerAttributes)
        "Horários de Trabalho".draw(at: CGPoint(x: margin + dateColumnWidth + 5, y: currentY), withAttributes: headerAttributes)
        "Horas".draw(at: CGPoint(x: margin + dateColumnWidth + timeColumnWidth + 5, y: currentY), withAttributes: headerAttributes)
        "Valor".draw(at: CGPoint(x: margin + dateColumnWidth + timeColumnWidth + hoursColumnWidth + 5, y: currentY), withAttributes: headerAttributes)
        
        currentY += 25
        
        return currentY
    }
    
    private static func drawEntries(cgContext: CGContext, entries: [WorkEntry], startIndex: Int, hourlyRate: Double, pageRect: CGRect, yPosition: inout CGFloat, tableStartY: CGFloat) -> Int {
        let margin: CGFloat = 50
        let dateColumnWidth: CGFloat = 80
        let timeColumnWidth: CGFloat = 280
        let hoursColumnWidth: CGFloat = 60
        
        let regularAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        
        var entriesDrawn = 0
        let maxYPosition = pageRect.height - 150 // Leave space for footer
        
        for index in startIndex..<entries.count {
            let entry = entries[index]
            let rowHeight = calculateRowHeight(for: entry)
            
            // Check if this entry fits on the current page
            if yPosition + rowHeight > maxYPosition && entriesDrawn > 0 {
                break // Start new page
            }
            
            // Alternate row background
            if (index - startIndex) % 2 == 0 {
                let rowRect = CGRect(x: margin, y: yPosition, width: pageRect.width - 2*margin, height: rowHeight)
                cgContext.setFillColor(UIColor.systemGray6.cgColor)
                cgContext.fill(rowRect)
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "pt_PT")
            dateFormatter.dateFormat = "d MMM"
            
            // Date - centered vertically in the row
            let dateText = dateFormatter.string(from: entry.day)
            let dateY = yPosition + (rowHeight - 12) / 2
            dateText.draw(at: CGPoint(x: margin + 5, y: dateY), withAttributes: regularAttributes)
            
            // Time periods - show all periods, each on a separate line
            var periodY = yPosition + 5
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            
            for (periodIndex, period) in entry.periods.enumerated() {
                let startTime = timeFormatter.string(from: period.startTime)
                let endTime = timeFormatter.string(from: period.endTime)
                let periodText = "Horário \(periodIndex + 1): \(startTime) - \(endTime)"
                
                // Use smaller font for individual periods if there are many
                let periodAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: entry.periods.count > 3 ? 10 : 11),
                    .foregroundColor: UIColor.black
                ]
                
                periodText.draw(at: CGPoint(x: margin + dateColumnWidth + 5, y: periodY), withAttributes: periodAttributes)
                periodY += (entry.periods.count > 3 ? 12 : 14)
            }
            
            // Hours - centered vertically in the row
            let hoursText = String(format: "%.1f", entry.workedHours)
            let hoursY = yPosition + (rowHeight - 12) / 2
            hoursText.draw(at: CGPoint(x: margin + dateColumnWidth + timeColumnWidth + 5, y: hoursY), withAttributes: regularAttributes)
            
            // Pay - centered vertically in the row
            let payText = String(format: "€%.2f", entry.calculatedPay(hourlyRate: hourlyRate))
            let payY = yPosition + (rowHeight - 12) / 2
            
            // Color code the pay based on whether it's paid or not
            let payColor = entry.isPaid ? UIColor.green : UIColor.red
            let payAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: payColor
            ]
            payText.draw(at: CGPoint(x: margin + dateColumnWidth + timeColumnWidth + hoursColumnWidth + 5, y: payY), withAttributes: payAttributes)
            
            yPosition += rowHeight
            entriesDrawn += 1
        }
        
        return entriesDrawn
    }
    
    private static func drawTableBorders(cgContext: CGContext, pageRect: CGRect, tableStartY: CGFloat, yPosition: CGFloat) {
        let margin: CGFloat = 50
        let dateColumnWidth: CGFloat = 80
        let timeColumnWidth: CGFloat = 280
        let hoursColumnWidth: CGFloat = 60
        
        // Draw table border
        let tableRect = CGRect(x: margin, y: tableStartY, width: pageRect.width - 2*margin, height: yPosition - tableStartY)
        cgContext.setStrokeColor(UIColor.black.cgColor)
        cgContext.setLineWidth(1)
        cgContext.stroke(tableRect)
        
        // Draw vertical lines for columns
        let columnXPositions: [CGFloat] = [
            margin + dateColumnWidth,
            margin + dateColumnWidth + timeColumnWidth,
            margin + dateColumnWidth + timeColumnWidth + hoursColumnWidth
        ]
        
        for xPos in columnXPositions {
            cgContext.move(to: CGPoint(x: xPos, y: tableStartY))
            cgContext.addLine(to: CGPoint(x: xPos, y: yPosition))
            cgContext.strokePath()
        }
    }
    
    private static func drawNotes(cgContext: CGContext, workMonth: WorkMonth, pageRect: CGRect, yPosition: inout CGFloat) {
        let margin: CGFloat = 50
        
        // Notes section (only if there's space and notes exist)
        if !workMonth.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && yPosition < pageRect.height - 150 {
            yPosition += 30
            
            let summaryAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.black
            ]
            
            "Notas:".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: summaryAttributes)
            yPosition += 20
            
            let notesRect = CGRect(x: margin, y: yPosition, width: pageRect.width - 2*margin, height: 80)
            cgContext.setStrokeColor(UIColor.lightGray.cgColor)
            cgContext.stroke(notesRect)
            
            let notesText = workMonth.notes
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 2
            
            let notesAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]
            
            notesText.draw(in: CGRect(x: margin + 5, y: yPosition + 5, width: pageRect.width - 2*margin - 10, height: 70),
                          withAttributes: notesAttributes)
        }
    }
    
    private static func drawFooter(cgContext: CGContext, pageRect: CGRect) {
        let margin: CGFloat = 50
        
        // Footer
        let footerY = pageRect.height - 30
        let footerText = "Gerado em \(Date().formatted(date: .abbreviated, time: .shortened))"
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),
            .foregroundColor: UIColor.gray
        ]
        footerText.draw(at: CGPoint(x: margin, y: footerY), withAttributes: footerAttributes)
    }

    // Helper function to calculate row height based on number of time periods
    private static func calculateRowHeight(for entry: WorkEntry) -> CGFloat {
        let periodsCount = entry.periods.count
        let baseHeight: CGFloat = 20
        
        if periodsCount <= 1 {
            return baseHeight
        } else if periodsCount <= 3 {
            return baseHeight + CGFloat(periodsCount - 1) * 14
        } else {
            return baseHeight + CGFloat(periodsCount - 1) * 12 // Smaller spacing for many periods
        }
    }
}

struct PDFPreviewView: View {
    let pdfData: Data
    let workMonth: WorkMonth
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            PDFKitView(data: pdfData)
                .navigationTitle("Pré-visualização")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Fechar") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: sharePDF) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
        }
    }
    
    private func sharePDF() {
        let cleanFileName = workMonth.name
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
        
        let fileName = "\(cleanFileName).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try pdfData.write(to: tempURL)
            
            let activityVC = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )
            
            activityVC.setValue(fileName, forKey: "subject")
            
            // Exclude potentially problematic activities
            activityVC.excludedActivityTypes = [
                .assignToContact,
                .addToReadingList
            ]
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                
                var topVC = rootVC
                while let presentedVC = topVC.presentedViewController {
                    topVC = presentedVC
                }
                
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = topVC.view
                    popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: 100, width: 0, height: 0)
                    popover.permittedArrowDirections = [.up]
                }
                
                topVC.present(activityVC, animated: true)
            }
            
            // Clean up after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                try? FileManager.default.removeItem(at: tempURL)
            }
            
        } catch {
            print("Failed to share PDF: \(error)")
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let data: Data
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(data: data)
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // No updates needed
    }
}

// MARK: - Updated MonthView with PDF Export
// Add this to your existing MonthView

extension MonthView {
    private var exportButton: some View {
        Button(action: exportToPDF) {
            HStack {
                Image(systemName: "doc.text")
                Text("Exportar PDF")
            }
        }
    }
    
    private func exportToPDF() {
        guard let pdfData = PDFGenerator.generatePDF(for: workMonth, hourlyRate: settings.hourlyRate) else {
            return
        }
        
        // For iOS - present share sheet
        let activityVC = UIActivityViewController(activityItems: [pdfData], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}
---
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Definições")
                .font(.title2)
                .bold()

            HStack {
                Text("€ por hora:")
                Spacer()
                TextField("Valor", value: $settings.hourlyRate, format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
            }
            .padding(.horizontal)

            Button("Fechar") {
                dismiss()
            }
            .padding(.top)
            .keyboardShortcut(.return, modifiers: [])

            Spacer()
        }
        .padding()
        .frame(minWidth: 300)
    }
}
---
import SwiftUI


@main
struct WorkTrackerApp: App {
    @StateObject var settings = AppSettings()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
        }
    }
}
