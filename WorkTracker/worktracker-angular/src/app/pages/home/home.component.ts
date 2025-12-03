import { Component, inject, OnInit, OnDestroy, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterOutlet, Router, NavigationEnd } from '@angular/router';
import { SidebarComponent } from '../../components/sidebar/sidebar.component';
import { NewSheetModalComponent } from '../../components/new-sheet-modal/new-sheet-modal.component';
import { SettingsModalComponent } from '../../components/settings-modal/settings-modal.component';
import { RenameModalComponent } from '../../components/rename-modal/rename-modal.component';
import { DataService } from '../../services/data.service';
import { WorkMonth } from '../../models/models';
import { filter, Subscription } from 'rxjs';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [CommonModule, RouterOutlet, SidebarComponent, NewSheetModalComponent, SettingsModalComponent, RenameModalComponent],
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.scss'],
  schemas: [CUSTOM_ELEMENTS_SCHEMA]
})
export class HomeComponent implements OnInit, OnDestroy {
  private router = inject(Router);
  private dataService = inject(DataService);
  private subs: Subscription[] = [];

  sidebarOpen = false;
  isMainPage = false; // Controla a visibilidade da sidebar

  // Modals state
  showNewSheet = false;
  showSettings = false;
  monthToRename: WorkMonth | null = null;

  ngOnInit() {
    // Verificar rota inicial e subscrever mudanças
    this.checkRoute();
    this.subs.push(
      this.router.events.pipe(
        filter(event => event instanceof NavigationEnd)
      ).subscribe(() => this.checkRoute())
    );

    // Escutar pedidos de criação vindos da lista
    this.subs.push(
      this.dataService.createSheetRequest.subscribe(() => this.openNewSheet())
    );
  }

  ngOnDestroy() {
    this.subs.forEach(s => s.unsubscribe());
  }

  private checkRoute() {
    // Esconde a sidebar se estivermos na raiz ('/')
    this.isMainPage = this.router.url === '/';
  }

  toggleSidebar() {
    this.sidebarOpen = !this.sidebarOpen;
  }

  openNewSheet() { this.showNewSheet = true; this.sidebarOpen = false; }
  openSettings() { this.showSettings = true; this.sidebarOpen = false; }
  openRename(month: WorkMonth) { this.monthToRename = month; }

  onNewSheetClose(data: WorkMonth | null) {
    this.showNewSheet = false;
    if (data) {
      this.dataService.addMonth(data);
      // Navegar para a nova folha imediatamente
      this.router.navigate(['/month', data.id]);
    }
  }

  onSettingsClose() { this.showSettings = false; }

  onRenameClose(result: { action: 'rename'|'delete'|'cancel', data?: any }) {
    if (this.monthToRename) {
      if (result.action === 'rename' && result.data) {
        this.dataService.updateMonth({ ...this.monthToRename, name: result.data });
      } else if (result.action === 'delete') {
        this.dataService.deleteMonth(this.monthToRename.id);
        this.router.navigate(['/']); // Volta para a lista se apagar
      }
    }
    this.monthToRename = null;
  }
}