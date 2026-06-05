import { Component, inject, computed, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { WorkMonth } from '../../models/models';
import { DataService } from '../../services/data.service';
import { SettingsModalComponent } from '../../components/settings-modal/settings-modal.component';
import { NewSheetModalComponent } from '../../components/new-sheet-modal/new-sheet-modal.component';

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

  // Active sheets sorted newest-first (current month at the top)
  sortedMonths = computed(() =>
    [...this.dataService.months()].sort(
      (a, b) => new Date(b.month).getTime() - new Date(a.month).getTime()
    )
  );

  daysRemaining(deletedAt: string): number {
    const elapsed = Date.now() - new Date(deletedAt).getTime();
    const elapsedDays = Math.floor(elapsed / (1000 * 60 * 60 * 24));
    return Math.max(0, 30 - elapsedDays);
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
