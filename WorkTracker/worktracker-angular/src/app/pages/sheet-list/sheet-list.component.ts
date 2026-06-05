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

    if (order === 'newest') {
      list.sort((a, b) => new Date(b.month).getTime() - new Date(a.month).getTime());
    } else if (order === 'oldest') {
      list.sort((a, b) => new Date(a.month).getTime() - new Date(b.month).getTime());
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

  daysRemaining(deletedAt: string): number {
    const elapsed = Date.now() - new Date(deletedAt).getTime();
    return Math.max(0, 30 - Math.floor(elapsed / (1000 * 60 * 60 * 24)));
  }

  createNew() { this.showNewSheet = true; }
  openSettings() { this.showSettings = true; }
  onSettingsClose() { this.showSettings = false; }
  openNewSheet() { this.showNewSheet = true; }
  toggleTrash() { this.showTrash = !this.showTrash; }

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
