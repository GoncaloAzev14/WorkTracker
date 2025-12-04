import { Component, Output, EventEmitter, inject, ViewChild, ElementRef, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { DataService } from '../../services/data.service';

@Component({
  selector: 'app-settings-modal',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './settings-modal.component.html',
  styleUrls: ['./settings-modal.component.scss'],
  schemas: [CUSTOM_ELEMENTS_SCHEMA]
})
export class SettingsModalComponent {
  @Output() close = new EventEmitter<void>();
  
  // Referência ao input de ficheiro escondido
  @ViewChild('fileInput') fileInput!: ElementRef<HTMLInputElement>;
  
  dataService = inject(DataService);
  rate: number;

  constructor() {
    this.rate = this.dataService.hourlyRate();
  }

  save() {
    this.dataService.updateHourlyRate(this.rate);
    this.close.emit();
  }

  // --- Lógica de Exportação ---
  exportData() {
    // 1. Compilar todos os dados atuais dos signals
    const backupData = {
      version: 1,
      date: new Date().toISOString(),
      settings: { hourlyRate: this.dataService.hourlyRate() },
      months: this.dataService.months()
    };

    // 2. Criar o ficheiro
    const json = JSON.stringify(backupData, null, 2);
    const blob = new Blob([json], { type: 'application/json' });
    const url = URL.createObjectURL(blob);

    // 3. Forçar o download
    const a = document.createElement('a');
    a.href = url;
    const dateStr = new Date().toISOString().split('T')[0];
    a.download = `worktracker-backup-${dateStr}.json`;
    a.click();
    
    // 4. Limpeza
    URL.revokeObjectURL(url);
  }

  triggerImport() {
    this.fileInput.nativeElement.click();
  }

  onFileSelected(event: Event) {
    const input = event.target as HTMLInputElement;
    if (!input.files || input.files.length === 0) return;

    const file = input.files[0];
    const reader = new FileReader();

    reader.onload = async (e) => {
      try {
        const json = e.target?.result as string;
        const data = JSON.parse(json);

        // Validação básica
        if (!data.months || !Array.isArray(data.months)) {
          throw new Error('Formato de ficheiro inválido');
        }

        if (confirm('Isto irá importar os dados para a Cloud (Firestore). Deseja continuar?')) {
          // Em vez de .set(), usamos o método especial de importação
          await this.dataService.importData(data.months);
          
          if (data.settings?.hourlyRate) {
            this.dataService.updateHourlyRate(data.settings.hourlyRate);
            this.rate = data.settings.hourlyRate;
          }
          
          alert('Dados importados com sucesso!');
          this.close.emit();
        }
      } catch (error) {
        console.error(error);
        alert('Erro ao importar. Ficheiro inválido ou erro de rede.');
      }
      
      // Limpar o input para permitir selecionar o mesmo ficheiro novamente se necessário
      input.value = '';
    };

    reader.readAsText(file);
  }
}