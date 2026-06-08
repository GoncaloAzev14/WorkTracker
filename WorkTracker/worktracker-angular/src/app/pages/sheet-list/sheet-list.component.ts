import { Component, inject, computed, signal, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { WorkMonth } from '../../models/models';
import { DataService } from '../../services/data.service';
import { SettingsModalComponent } from '../../components/settings-modal/settings-modal.component';
import { NewSheetModalComponent } from '../../components/new-sheet-modal/new-sheet-modal.component';

type SortOrder = 'newest' | 'oldest' | 'name';

@Component({
  selector: 'app-sheet-list',
  standalone: true,
  imports: [CommonModule, RouterModule, SettingsModalComponent, NewSheetModalComponent],
  templateUrl: './sheet-list.component.html',
  styleUrls: ['./sheet-list.component.scss'],
  schemas: [CUSTOM_ELEMENTS_SCHEMA]
})
export class SheetListComponent {
  public dataService = inject(DataService);
  showSettings = false;
  showNewSheet = false;

  // --- SEARCH & SORT ---
  searchTerm = signal('');
  sortOrder = signal<SortOrder>('newest');

  filteredMonths = computed(() => {
    const term = this.searchTerm().toLowerCase().trim();
    const order = this.sortOrder();
    let list = [...this.dataService.months()];

    if (term) {
      list = list.filter(m =>
        m.name.toLowerCase().includes(term) ||
        new Date(m.month).toLocaleDateString('pt-PT', { month: 'long', year: 'numeric' }).toLowerCase().includes(term) ||
        new Date(m.month).getFullYear().toString().includes(term)
      );
    }

    const ts = (m: WorkMonth) =>
      m.createdAt ? new Date(m.createdAt).getTime() : parseInt(m.id.slice(-8), 36);

    if (order === 'newest') {
      list.sort((a, b) => ts(b) - ts(a));
    } else if (order === 'oldest') {
      list.sort((a, b) => ts(a) - ts(b));
    } else {
      list.sort((a, b) => a.name.localeCompare(b.name, 'pt'));
    }

    return list;
  });

  setSearch(event: Event) {
    this.searchTerm.set((event.target as HTMLInputElement).value);
  }

  setSortOrder(order: SortOrder) { this.sortOrder.set(order); }

  // --- BULK SELECTION ---
  selectionMode = false;
  selectedIds = signal<Set<string>>(new Set());

  selectedCount = computed(() => this.selectedIds().size);

  allSelected = computed(() => {
    const visible = this.filteredMonths();
    const sel = this.selectedIds();
    return visible.length > 0 && visible.every(m => sel.has(m.id));
  });

  toggleSelectionMode() {
    this.selectionMode = !this.selectionMode;
    if (!this.selectionMode) this.selectedIds.set(new Set());
  }

  toggleSelect(id: string) {
    const next = new Set(this.selectedIds());
    next.has(id) ? next.delete(id) : next.add(id);
    this.selectedIds.set(next);
  }

  isSelected(id: string): boolean { return this.selectedIds().has(id); }

  toggleSelectAll() {
    if (this.allSelected()) {
      this.selectedIds.set(new Set());
    } else {
      this.selectedIds.set(new Set(this.filteredMonths().map(m => m.id)));
    }
  }

  async deleteSelected() {
    const ids = [...this.selectedIds()];
    if (ids.length === 0) return;
    const label = ids.length === 1 ? '1 folha' : `${ids.length} folhas`;
    if (confirm(`Mover ${label} para o lixo? Podes recuperá-las nos próximos 30 dias.`)) {
      await Promise.all(ids.map(id => this.dataService.softDeleteMonth(id)));
      this.selectedIds.set(new Set());
      this.selectionMode = false;
    }
  }

  createNew()    { this.showNewSheet = true; }
  openSettings() { this.showSettings = true; }

  async onNewSheetClose(data: WorkMonth | null) {
    this.showNewSheet = false;
    if (data) await this.dataService.addMonth(data);
  }
}
