import { Component, inject, signal, effect, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute } from '@angular/router';
import { DataService } from '../../services/data.service';
import { PdfService } from '../../services/pdf.service';
import { WorkMonth, WorkEntry, WorkPeriod, entryHours, generateId } from '../../models/models';
import { DayEditorComponent } from '../../components/day-editor/day-editor.component';

@Component({
  selector: 'app-month-detail',
  standalone: true,
  imports: [CommonModule, FormsModule, DayEditorComponent],
  templateUrl: './month-detail.component.html',
  styleUrls: ['./month-detail.component.scss'],
  schemas: [CUSTOM_ELEMENTS_SCHEMA]
})
export class MonthDetailComponent {
  private route = inject(ActivatedRoute);
  private pdfService = inject(PdfService);
  public dataService = inject(DataService);

  month = signal<WorkMonth | null>(null);
  sortedEntries = signal<WorkEntry[]>([]);
  totalEstimated = signal(0);
  totalActual = signal(0);
  allPaid = signal(false);

  notesOpen = false;

  // Modals
  editingEntry: WorkEntry | null = null;

  constructor() {
    this.route.paramMap.subscribe(params => {
      const id = params.get('id');
      if (id) this.updateLocalMonth(id);
    });

    effect(() => {
      const currentId = this.month()?.id;
      if (currentId) this.updateLocalMonth(currentId);
    });
  }

  updateLocalMonth(id: string) {
    const found = this.dataService.months().find(m => m.id === id);
    if (found) {
      this.month.set(found);
      const sorted = [...found.entries].sort((a, b) => new Date(a.day).getTime() - new Date(b.day).getTime());
      this.sortedEntries.set(sorted);

      const rate = this.dataService.hourlyRate();
      const est = found.entries.reduce((sum, e) => sum + entryHours(e) * rate, 0);
      const act = found.entries.filter(e => e.isPaid).reduce((sum, e) => sum + entryHours(e) * rate, 0);

      this.totalEstimated.set(est);
      this.totalActual.set(act);
      this.allPaid.set(found.entries.length > 0 && found.entries.every(e => e.isPaid));
    }
  }

  togglePaid(entry: WorkEntry, event: Event) {
    event.stopPropagation();
    if (!this.month()) return;
    const updated = { ...entry, isPaid: !entry.isPaid };
    this.updateEntryInMonth(updated);
  }

  toggleSelectAll() {
    const m = this.month();
    if (!m) return;
    const newState = !this.allPaid();
    const newEntries = m.entries.map(e => ({ ...e, isPaid: newState }));
    this.dataService.updateMonth({ ...m, entries: newEntries });
  }

  updateNotes() {
    const m = this.month();
    if (m) this.dataService.updateMonth({ ...m });
  }

  exportPDF() {
    const m = this.month();
    if (m) this.pdfService.exportMonth(m, this.dataService.hourlyRate());
  }

  // Helpers
  getEntryHours(entry: WorkEntry) { return entryHours(entry); }
  getEntryPay(entry: WorkEntry) { return entryHours(entry) * this.dataService.hourlyRate(); }

  // Modal Handlers
  openEntry(entry: WorkEntry) { this.editingEntry = entry; }
  onEntryClose(updated: WorkEntry | null) {
    this.editingEntry = null;
    if (updated) this.updateEntryInMonth(updated);
  }

  openAddDay() {
    const m = this.month();
    if (!m) return;

    // Encontrar o último dia registado
    const entries = [...m.entries].sort((a, b) => new Date(a.day).getTime() - new Date(b.day).getTime());
    let targetDate: Date;

    if (entries.length === 0) {
      // Se não houver entradas, começa no dia 1 do mês da folha
      targetDate = new Date(m.month);
    } else {
      // Senão, é o dia seguinte ao último registo
      const lastEntryDate = new Date(entries[entries.length - 1].day);
      targetDate = new Date(lastEntryDate);
      targetDate.setDate(targetDate.getDate() + 1);
    }

    // Verificar se ainda estamos no mesmo mês
    const monthStart = new Date(m.month);
    if (targetDate.getMonth() !== monthStart.getMonth()) {
      alert('O mês já está completo (chegou ao fim do mês).');
      return;
    }

    this.createEntry(targetDate.toISOString());
  }


  private createEntry(dateIso: string) {
    const m = this.month();
    if (!m) return;

    const date = new Date(dateIso);
    const dayOfWeek = date.getDay(); // 0 = Domingo, 6 = Sábado
    const periods: WorkPeriod[] = [];

    if (dayOfWeek === 0) {
      // Domingo: sem horário definido (mantém array vazio)
    } 
    else if (dayOfWeek === 6) {
      // Sábado: 08:00 - 12:00
      const start = new Date(date); start.setHours(8, 0, 0, 0);
      const end = new Date(date); end.setHours(12, 0, 0, 0);
      periods.push({ id: generateId(), startTime: start.toISOString(), endTime: end.toISOString() });
    } 
    else {
      // Semana (Seg-Sex): 17:00 - 20:00
      const start = new Date(date); start.setHours(17, 0, 0, 0);
      const end = new Date(date); end.setHours(20, 0, 0, 0);
      periods.push({ id: generateId(), startTime: start.toISOString(), endTime: end.toISOString() });
    }
    
    const newEntry: WorkEntry = {
      id: generateId(),
      day: dateIso,
      periods: periods,
      isPaid: false
    };
    
    this.dataService.updateMonth({ ...m, entries: [...m.entries, newEntry] });
  }

  private updateEntryInMonth(updated: WorkEntry) {
    const m = this.month();
    if (!m) return;
    const entries = m.entries.map(e => e.id === updated.id ? updated : e);
    this.dataService.updateMonth({ ...m, entries });
  }
}