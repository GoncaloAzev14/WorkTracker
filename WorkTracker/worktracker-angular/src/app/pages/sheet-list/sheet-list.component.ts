import { Component, inject, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { DataService } from '../../services/data.service';
@Component({
  selector: 'app-sheet-list',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './sheet-list.component.html',
  styleUrls: ['./sheet-list.component.scss'],
  schemas: [CUSTOM_ELEMENTS_SCHEMA]
})
export class SheetListComponent {
  public dataService = inject(DataService);

  createNew() {
    this.dataService.createSheetRequest.next();
  }
}