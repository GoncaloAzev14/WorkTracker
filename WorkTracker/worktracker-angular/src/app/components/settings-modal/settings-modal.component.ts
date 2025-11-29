import { Component, Output, EventEmitter, inject, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { DataService } from '../../services/data.service';

@Component({
  selector: 'app-settings-modal',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './settings-modal.component.html',
  schemas: [CUSTOM_ELEMENTS_SCHEMA]
})
export class SettingsModalComponent {
  @Output() close = new EventEmitter<void>();
  dataService = inject(DataService);
  rate: number;

  constructor() {
    this.rate = this.dataService.hourlyRate();
  }

  save() {
    this.dataService.updateHourlyRate(this.rate);
    this.close.emit();
  }
}