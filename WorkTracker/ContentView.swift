import SwiftUI

struct ContentView: View {
    @State private var months: [WorkMonth] = []
    @State private var showRenameSheet = false
    @State private var selectedMonth: WorkMonth?
    @State private var renameText: String = ""
    @State private var showDeleteConfirmation = false
    @State private var monthToDelete: WorkMonth?
    @State private var selectedMonthID: WorkMonth.ID? = nil // Para controlar qual folha está selecionada
    @State private var showNewSheetDialog = false
    @State private var newSheetName = ""
    
    var body: some View {
        NavigationSplitView {
            // Sidebar (lado esquerdo)
            VStack {
                List(months, selection: $selectedMonthID) { month in
                    Text(month.name.isEmpty ? "Sem Título" : month.name)
                        .tag(month.id)
                        .contextMenu {
                            Button("Renomear") {
                                selectedMonth = month
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

                TextField("Nome da folha", text: $newSheetName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onSubmit {
                        criarNovaFolha()
                    }

                HStack(spacing: 20) {
                    Button("Cancelar") {
                        showNewSheetDialog = false
                    }
                    .foregroundColor(.secondary)
                    
                    Button("Criar") {
                        criarNovaFolha()
                    }
                    .disabled(newSheetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
            .padding()
            .frame(minWidth: 300)
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
                if let selected = selectedMonth {
                    renameText = selected.name
                }
            }
        }
    }
    
    // Função para criar nova folha
    private func criarNovaFolha() {
        let trimmedName = newSheetName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let newMonth = WorkMonth(
            month: Date(),
            entries: [],
            notes: "",
            name: trimmedName
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
        
        if selectedMonth?.id == month.id {
            selectedMonth = nil
        }
    }
    
    private func binding(for month: WorkMonth) -> Binding<WorkMonth> {
        guard let index = months.firstIndex(where: { $0.id == month.id }) else {
            fatalError("Month not found")
        }
        return $months[index]
    }
    
    func guardarNome() {
        if let selected = selectedMonth,
           let index = months.firstIndex(where: { $0.id == selected.id }) {
            months[index].name = renameText
        }
        showRenameSheet = false
    }
}
