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
  showTrash = false;

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
        new Date(m.month).toLocaleDateString('pt-PT', { month: 'long', year: 'numeric' }).toLowerCase().includes(term)
      );
    }

    // createdAt is set on new sheets. For older sheets that predate the field,
    // fall back to the timestamp encoded inside the ID itself:
    // generateId() = random_part + Date.now().toString(36)
    // Modern Date.now() values are always 8 base-36 digits, so slice(-8) is reliable.
    const ts = (m: WorkMonth) =>
      m.createdAt
        ? new Date(m.createdAt).getTime()
        : parseInt(m.id.slice(-8), 36);

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

  setSortOrder(order: SortOrder) {
    this.sortOrder.set(order);
  }

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
    if (!this.selectionMode) {
      this.selectedIds.set(new Set());
    }
  }

  toggleSelect(id: string) {
    const next = new Set(this.selectedIds());
    next.has(id) ? next.delete(id) : next.add(id);
    this.selectedIds.set(next);
  }

  isSelected(id: string): boolean {
    return this.selectedIds().has(id);
  }

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

  // --- OTHER ---
  daysRemaining(deletedAt: string): number {
    const elapsed = Date.now() - new Date(deletedAt).getTime();
    return Math.max(0, 30 - Math.floor(elapsed / (1000 * 60 * 60 * 24)));
  }

  createNew() { this.showNewSheet = true; }
  openSettings() { this.showSettings = true; }
  onSettingsClose() { this.showSettings = false; }
  openNewSheet() { this.showNewSheet = true; }

  toggleTrash() {
    this.showTrash = !this.showTrash;
    if (this.showTrash && this.selectionMode) {
      this.selectionMode = false;
      this.selectedIds.set(new Set());
    }
  }

  async onNewSheetClose(data: WorkMonth | null) {
    this.showNewSheet = false;
    if (data) await this.dataService.addMonth(data);
  }

  async recover(id: string) {
    await this.dataService.recoverMonth(id);
  }

  async permanentlyDelete(id: string, name: string) {
    if (confirm(`Apagar "${name}" permanentemente? Esta ação não pode ser desfeita.`)) {
      await this.dataService.permanentlyDeleteMonth(id);
    }
  }
}
