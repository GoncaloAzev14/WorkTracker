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
  @ViewChild('fileInput') fileInput!: ElementRef<HTMLInputElement>;

  dataService = inject(DataService);
  private auth = inject(Auth);
  private router = inject(Router);

  rate: number = 0;
  activeMonth: WorkMonth | undefined;
  isMonthMode = false;
  monthName: string = '';

  // Sub-page navigation (iOS-style within the modal)
  currentView: 'main' | 'trash' = 'main';

  navigateToTrash() { this.currentView = 'trash'; }
  navigateBack()    { this.currentView = 'main'; }

  daysRemaining(deletedAt: string): number {
    const elapsed = Date.now() - new Date(deletedAt).getTime();
    return Math.max(0, 30 - Math.floor(elapsed / (1000 * 60 * 60 * 24)));
  }

  async recoverMonth(id: string) {
    await this.dataService.recoverMonth(id);
  }

  async permanentlyDeleteMonth(id: string, name: string) {
    if (confirm(`Apagar "${name}" permanentemente? Esta ação não pode ser desfeita.`)) {
      await this.dataService.permanentlyDeleteMonth(id);
    }
  }

  ngOnInit() {
    const activeId = this.dataService.activeMonthId();
    if (activeId) {
      this.activeMonth = this.dataService.months().find(m => m.id === activeId);
      if (this.activeMonth) {
        this.isMonthMode = true;
        this.rate = this.activeMonth.hourlyRate ?? this.dataService.hourlyRate();
        this.monthName = this.activeMonth.name;
      }
    } else {
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
          await deleteUser(user);
          alert('Conta eliminada.');
          this.close.emit();
          this.router.navigate(['/login']);
        } catch (error: any) {
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
      const updatedMonth = { ...this.activeMonth, hourlyRate: this.rate, name: this.monthName };
      this.dataService.updateMonth(updatedMonth);
    } else {
      this.dataService.updateHourlyRate(this.rate);
    }
    this.close.emit();
  }

  exportData() {
    const backupData = {
      version: 1,
      date: new Date().toISOString(),
      settings: { hourlyRate: this.dataService.hourlyRate() },
      months: this.dataService.months()
    };
    const json = JSON.stringify(backupData, null, 2);
    const blob = new Blob([json], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `worktracker-backup-${new Date().toISOString().split('T')[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);
  }

  triggerImport() { this.fileInput.nativeElement.click(); }

  onFileSelected(event: Event) {
    const input = event.target as HTMLInputElement;
    if (!input.files || input.files.length === 0) return;
    const file = input.files[0];
    const reader = new FileReader();
    reader.onload = async (e) => {
      try {
        const json = e.target?.result as string;
        const data = JSON.parse(json);
        if (!data.months || !Array.isArray(data.months)) throw new Error('Formato inválido');
        if (confirm('Isto irá importar os dados para a Cloud (Firestore). Deseja continuar?')) {
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
      input.value = '';
    };
    reader.readAsText(file);
  }
}
