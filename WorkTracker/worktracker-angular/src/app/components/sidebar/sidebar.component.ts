import { Component, EventEmitter, Output, inject, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { DataService } from '../../services/data.service';
import { WorkMonth } from '../../models/models';

@Component({
  selector: 'app-sidebar',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './sidebar.component.html',
  styleUrls: ['./sidebar.component.scss'],
  schemas: [CUSTOM_ELEMENTS_SCHEMA]
})
export class SidebarComponent {
  public dataService = inject(DataService);

  @Output() closeMenu = new EventEmitter<void>();
  @Output() requestNewSheet = new EventEmitter<void>();
  @Output() requestSettings = new EventEmitter<void>();
  @Output() requestRename = new EventEmitter<WorkMonth>();

  selectMonth() {
    this.closeMenu.emit();
  }

  onRename(month: WorkMonth, event: Event) {
    event.stopPropagation();
    event.preventDefault();
    this.requestRename.emit(month);
  }
}