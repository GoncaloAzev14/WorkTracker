import SwiftUI

struct ContentView: View {
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
                    Spacer()
                    Text("\(months.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.secondary.opacity(0.2))
                        .clipShape(Capsule())
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
                                Text("€\(String(format: "%.0f", month.totalPay(hourlyRate: 5.0)))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
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
                        .cornerRadius(8)
                    }
                    
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
