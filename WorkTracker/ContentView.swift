import SwiftUI

struct ContentView: View {
    @State private var months: [WorkMonth] = []
    @State private var showRenameSheet = false
    @State private var selectedMonthForRename: WorkMonth? // Renomeado para evitar conflito
    @State private var renameText: String = ""
    @State private var showDeleteConfirmation = false
    @State private var monthToDelete: WorkMonth?
    @State private var selectedMonthID: WorkMonth.ID? = nil // Para controlar qual folha está selecionada
    @State private var showNewSheetDialog = false
    @State private var newSheetName = ""
    @State private var selectedMonthNumber = Calendar.current.component(.month, from: Date()) // Renomeado para evitar conflito
    
    var body: some View {
        NavigationSplitView {
            // Sidebar (lado esquerdo)
            VStack {
                List(months, selection: $selectedMonthID) { month in
                    Text(month.name.isEmpty ? "Sem Título" : month.name)
                        .tag(month.id)
                        .contextMenu {
                            Button("Renomear") {
                                selectedMonthForRename = month
                                showRenameSheet = true
                            }
                            
                            Button("Apagar", role: .destructive) {
                                // Verificar se a folha tem conteúdo
                                let hasContent = !month.entries.isEmpty || !month.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                
                                if hasContent {
                                    // Se tem conteúdo, mostrar alert de confirmação
                                    monthToDelete = month
                                    showDeleteConfirmation = true
                                } else {
                                    // Se está vazia, apagar diretamente
                                    deleteMonth(month)
                                }
                            }
                        }
                }
                .navigationTitle("Meses")
                
                // Botão Nova Folha dentro do sidebar
                Button(action: {
                    newSheetName = ""
                    selectedMonthNumber = Calendar.current.component(.month, from: Date()) // Resetar para mês atual
                    showNewSheetDialog = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Nova Folha")
                            .fixedSize()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .help("Nova Folha")
                .padding(.horizontal)
                .padding(.bottom)
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
            // Vista de detalhe (lado direito)
            if let selectedMonthID = selectedMonthID,
               let selectedMonth = months.first(where: { $0.id == selectedMonthID }) {
                MonthView(workMonth: binding(for: selectedMonth))
            } else {
                // Vista placeholder quando nada está selecionado
                VStack {
                    Image(systemName: "doc.text")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("Seleciona uma folha")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Escolhe uma folha da lista para começar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .sheet(isPresented: $showNewSheetDialog) {
            VStack(spacing: 20) {
                Text("Nova Folha")
                    .font(.headline)

                TextField("Nome da folha (opcional)", text: $newSheetName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .onSubmit {
                        criarNovaFolha()
                    }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Mês:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Picker("Selecionar Mês", selection: $selectedMonthNumber) {
                        ForEach(1...12, id: \.self) { month in
                            Text(monthName(for: month))
                                .tag(month)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)

                HStack(spacing: 20) {
                    Button("Cancelar") {
                        showNewSheetDialog = false
                    }
                    .foregroundColor(.secondary)
                    
                    Button("Criar") {
                        criarNovaFolha()
                    }
                    // Remover a condição de disabled - sempre permitir criar
                }
                .padding()
            }
            .padding()
            .frame(minWidth: 350)
        }
        .sheet(isPresented: $showRenameSheet) {
            VStack(spacing: 20) {
                Text("Renomear folha")
                    .font(.headline)

                TextField("Novo nome", text: $renameText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onSubmit {
                        guardarNome()
                    }

                Button("Guardar") {
                    guardarNome()
                }
                .padding()
            }
            .padding()
            .onAppear {
                if let selected = selectedMonthForRename {
                    renameText = selected.name
                }
            }
        }
    }
    
    // Função para obter o nome do mês
    private func monthName(for month: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_PT")
        return formatter.monthSymbols[month - 1]
    }
    
    // Função para criar nova folha
    private func criarNovaFolha() {
        let trimmedName = newSheetName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let finalName = trimmedName.isEmpty ? monthName(for: selectedMonthNumber).capitalized.appending(" ").appending(String(Calendar.current.component(.year, from: Date()))) : trimmedName
        
        var dateComponents = DateComponents()
        dateComponents.year = Calendar.current.component(.year, from: Date())
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
        showNewSheetDialog = false
        
        // Opcional: selecionar automaticamente a nova folha criada
        selectedMonthID = newMonth.id
    }
    
    // Função auxiliar para apagar uma folha
    private func deleteMonth(_ month: WorkMonth) {
        // Se estamos a apagar a folha selecionada, limpar a seleção
        if selectedMonthID == month.id {
            selectedMonthID = nil
        }
        
        if let index = months.firstIndex(where: { $0.id == month.id }) {
            months.remove(at: index)
        }
        
        if selectedMonthForRename?.id == month.id {
            selectedMonthForRename = nil
        }
    }
    
    private func binding(for month: WorkMonth) -> Binding<WorkMonth> {
        guard let index = months.firstIndex(where: { $0.id == month.id }) else {
            fatalError("Month not found")
        }
        return $months[index]
    }
    
    func guardarNome() {
        if let selected = selectedMonthForRename,
           let index = months.firstIndex(where: { $0.id == selected.id }) {
            months[index].name = renameText
        }
        showRenameSheet = false
    }
}
