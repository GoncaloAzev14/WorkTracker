import { Component, Output, EventEmitter, inject, ViewChild, ElementRef, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { Router } from '@angular/router';
import { Auth, signOut, deleteUser } from '@angular/fire/auth';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { DataService } from '../../services/data.service';
import { WorkMonth } from '../../models/models';

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
  @Output() openTrash = new EventEmitter<void>();
  @ViewChild('fileInput') fileInput!: ElementRef<HTMLInputElement>;

  dataService = inject(DataService);
  private auth = inject(Auth);
  private router = inject(Router);

  rate: number = 0;
  activeMonth: WorkMonth | undefined;
  isMonthMode = false;
  monthName: string = '';

  viewTrash() {
    this.openTrash.emit();
    this.close.emit();
  }

  ngOnInit() {
    const activeId = this.dataService.activeMonthId();
    
    if (activeId) {
      // MODO FOLHA: Estamos dentro de um mês
      this.activeMonth = this.dataService.months().find(m => m.id === activeId);
      if (this.activeMonth) {
        this.isMonthMode = true;
        // Carrega a taxa do mês (ou a global se o mês ainda não tiver taxa própria)
        this.rate = this.activeMonth.hourlyRate ?? this.dataService.hourlyRate();
        this.monthName = this.activeMonth.name;
      }
    } else {
      // MODO GERAL: Estamos na Home
      this.isMonthMode = false;
      this.rate = this.dataService.hourlyRate();
    }
  }

  async logout() {
    try {
      await signOut(this.auth);
      this.close.emit();
      this.router.navigate(['/login']);
    } catch (error) {
      console.error('Erro ao sair', error);
    }
  }

  async deleteAccount() {
    if (confirm('ATENÇÃO: Isto irá apagar a tua conta e TODOS os teus dados permanentemente. Tens a certeza?')) {
      const user = this.auth.currentUser;
      if (user) {
        try {
          // Nota: Numa app real de produção, deverias apagar os dados do Firestore primeiro.
          // O Firebase Auth apaga o login, mas os dados ficam "órfãos" na BD a menos que tenhas uma Cloud Function.
          await deleteUser(user);
          alert('Conta eliminada.');
          this.close.emit();
          this.router.navigate(['/login']);
        } catch (error: any) {
          // Se o login for muito antigo, o Firebase pede para fazer login de novo antes de apagar
          if (error.code === 'auth/requires-recent-login') {
            alert('Por segurança, faz login novamente antes de apagar a conta.');
            this.logout();
          } else {
            alert('Erro ao apagar conta: ' + error.message);
          }
        }
      }
    }
  }

  save() {
    if (this.isMonthMode && this.activeMonth) {
      // Grava apenas na FOLHA ATUAL
      const updatedMonth = { ...this.activeMonth, hourlyRate: this.rate, name: this.monthName };
      this.dataService.updateMonth(updatedMonth);
    } else {
      // Grava nas DEFINIÇÕES GERAIS
      this.dataService.updateHourlyRate(this.rate);
    }
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