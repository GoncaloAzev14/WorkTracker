import { Component, inject, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
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

  createNew() {
    this.showNewSheet = true;
  }

  openSettings() {
    this.showSettings = true;
  }
  
  onSettingsClose() {
    this.showSettings = false;
  }

  async onNewSheetClose(data: WorkMonth | null) {
    this.showNewSheet = false;
    if (data) {
      await this.dataService.addMonth(data);
    }
  }

  openNewSheet() { this.showNewSheet = true; }
}