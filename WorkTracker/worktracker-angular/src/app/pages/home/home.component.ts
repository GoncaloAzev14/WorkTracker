import { Component, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterOutlet } from '@angular/router';
import { SidebarComponent } from '../../components/sidebar/sidebar.component';
import { NewSheetModalComponent } from '../../components/new-sheet-modal/new-sheet-modal.component';
import { SettingsModalComponent } from '../../components/settings-modal/settings-modal.component';
import { RenameModalComponent } from '../../components/rename-modal/rename-modal.component';
import { DataService } from '../../services/data.service';
import { WorkMonth } from '../../models/models';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [CommonModule, RouterOutlet, SidebarComponent, NewSheetModalComponent, SettingsModalComponent, RenameModalComponent],
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.scss'],
  schemas: [CUSTOM_ELEMENTS_SCHEMA]
})
export class HomeComponent {
  sidebarOpen = false; // Mobile

  // Modals state
  showNewSheet = false;
  showSettings = false;
  monthToRename: WorkMonth | null = null;

  constructor(private dataService: DataService) {}

  toggleSidebar() {
    this.sidebarOpen = !this.sidebarOpen;
  }

  // Ações chamadas pelo Sidebar
  openNewSheet() { this.showNewSheet = true; this.sidebarOpen = false; }
  openSettings() { this.showSettings = true; this.sidebarOpen = false; }
  openRename(month: WorkMonth) { this.monthToRename = month; }

  // Callbacks dos Modais
  onNewSheetClose(data: WorkMonth | null) {
    this.showNewSheet = false;
    if (data) this.dataService.addMonth(data);
  }

  onSettingsClose() {
    this.showSettings = false;
  }

  onRenameClose(result: { action: 'rename'|'delete'|'cancel', data?: any }) {
    if (this.monthToRename) {
      if (result.action === 'rename' && result.data) {
        this.dataService.updateMonth({ ...this.monthToRename, name: result.data });
      } else if (result.action === 'delete') {
        this.dataService.deleteMonth(this.monthToRename.id);
      }
    }
    this.monthToRename = null;
  }
}