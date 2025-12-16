import { Component, inject, signal, computed, effect, CUSTOM_ELEMENTS_SCHEMA, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute } from '@angular/router';
import { DataService } from '../../services/data.service';
import { PdfService } from '../../services/pdf.service';
import { WorkEntry, entryHours, generateId, WorkPeriod } from '../../models/models';
import { DayEditorComponent } from '../../components/day-editor/day-editor.component';

@Component({
  selector: 'app-month-detail',
  standalone: true,
  imports: [CommonModule, FormsModule, DayEditorComponent],
  templateUrl: './month-detail.component.html',
  styleUrls: ['./month-detail.component.scss'],
  schemas: [CUSTOM_ELEMENTS_SCHEMA]
})
export class MonthDetailComponent implements OnDestroy {
  private route = inject(ActivatedRoute);
  private pdfService = inject(PdfService);
  public dataService = inject(DataService);

  // ID do mês atual vindo da rota
  currentMonthId = signal<string | null>(null);

  // REATIVIDADE MÁGICA:
  // Este computed atualiza-se AUTOMATICAMENTE assim que os dados chegarem do Firebase
  month = computed(() => {
    const id = this.currentMonthId();
    const months = this.dataService.months(); // Lista vinda da Cloud
    return months.find(m => m.id === id) || null;
  });

  // Calcular entradas ordenadas baseadas no mês encontrado
  sortedEntries = computed(() => {
    const m = this.month();
    if (!m) return [];
    return [...m.entries].sort((a, b) => new Date(a.day).getTime() - new Date(b.day).getTime());
  });

  // Totais calculados automaticamente
  totals = computed(() => {
    const m = this.month();
    const rate = m?.hourlyRate ?? this.dataService.hourlyRate(); 

    if (!m) return { estimated: 0, actual: 0, allPaid: false, rateUsed: rate };

    const est = m.entries.reduce((sum, e) => sum + entryHours(e) * rate, 0);
    const act = m.entries.filter(e => e.isPaid).reduce((sum, e) => sum + entryHours(e) * rate, 0);
    const allPaid = m.entries.length > 0 && m.entries.every(e => e.isPaid);

    return { estimated: est, actual: act, allPaid, rateUsed: rate };
  });

  notesOpen = false;
  editingEntry: WorkEntry | null = null;

  constructor() {
    // Apanhar o ID da rota
    this.route.paramMap.subscribe(params => {
      const id = params.get('id');
      this.currentMonthId.set(id);

      this.dataService.activeMonthId.set(id);
    });
  }

  ngOnDestroy() {
    this.dataService.activeMonthId.set(null);
  }

  // --- Ações ---

  togglePaid(entry: WorkEntry, event: Event) {
    event.stopPropagation();
    const m = this.month();
    if (!m) return;
    const updated = { ...entry, isPaid: !entry.isPaid };
    this.updateEntryInMonth(m, updated);
  }

  toggleSelectAll() {
    const m = this.month();
    if (!m) return;
    const newState = !this.totals().allPaid;
    const newEntries = m.entries.map(e => ({ ...e, isPaid: newState }));
    // Nota: Passamos 'm' porque não podemos aceder a this.month() dentro do updateMonth se ele for signal read-only
    this.dataService.updateMonth({ ...m, entries: newEntries });
  }

  updateNotes() {
    const m = this.month();
    if (m) this.dataService.updateMonth({ ...m }); // O ngModel atualiza a ref local, aqui guardamos na cloud
  }

  exportPDF() {
    const m = this.month();
    if (m) this.pdfService.exportMonth(m, this.totals().rateUsed ?? this.dataService.hourlyRate());
  }

  // Helpers
  getEntryHours(entry: WorkEntry) { return entryHours(entry); }
  getEntryPay(entry: WorkEntry) { return entryHours(entry) * this.totals().rateUsed; }

  // Modal Handlers
  openEntry(entry: WorkEntry) { this.editingEntry = entry; }
  
  onEntryClose(updated: WorkEntry | null) {
    this.editingEntry = null;
    const m = this.month();
    if (updated && m) this.updateEntryInMonth(m, updated);
  }

  openAddDay() {
    const m = this.month();
    const entries = this.sortedEntries();
    if (!m) return;

    let targetDate: Date;
    if (entries.length === 0) {
      targetDate = new Date(m.month);
    } else {
      const lastEntryDate = new Date(entries[entries.length - 1].day);
      targetDate = new Date(lastEntryDate);
      targetDate.setDate(targetDate.getDate() + 1);
    }

    const monthStart = new Date(m.month);
    if (targetDate.getMonth() !== monthStart.getMonth()) {
      alert('O mês já está completo.');
      return;
    }
    this.createEntry(m, targetDate.toISOString());
  }

  private createEntry(m: any, dateIso: string) {
    const date = new Date(dateIso);
    const dayOfWeek = date.getDay();
    const periods: WorkPeriod[] = [];

    if (dayOfWeek === 6) { // Sábado
      const s = new Date(date); s.setHours(8,0,0,0);
      const e = new Date(date); e.setHours(12,0,0,0);
      periods.push({ id: generateId(), startTime: s.toISOString(), endTime: e.toISOString() });
    } else if (dayOfWeek !== 0) { // Semana
      const s = new Date(date); s.setHours(17,0,0,0);
      const e = new Date(date); e.setHours(20,0,0,0);
      periods.push({ id: generateId(), startTime: s.toISOString(), endTime: e.toISOString() });
    }

    const newEntry: WorkEntry = {
      id: generateId(),
      day: dateIso,
      periods: periods,
      isPaid: false
    };
    
    this.dataService.updateMonth({ ...m, entries: [...m.entries, newEntry] });
  }

  private updateEntryInMonth(month: any, updated: WorkEntry) {
    const entries = month.entries.map((e: WorkEntry) => e.id === updated.id ? updated : e);
    this.dataService.updateMonth({ ...month, entries });
  }
}