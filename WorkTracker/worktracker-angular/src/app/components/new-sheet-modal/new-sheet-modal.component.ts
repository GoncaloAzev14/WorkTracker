import { Component, Output, EventEmitter, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { WorkMonth, generateId } from '../../models/models';

@Component({
  selector: 'app-new-sheet-modal',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './new-sheet-modal.component.html',
  styleUrls: ['./new-sheet-modal.component.scss'], // Usa global css se vazio
  schemas: [CUSTOM_ELEMENTS_SCHEMA]
})
export class NewSheetModalComponent {
  @Output() close = new EventEmitter<WorkMonth | null>();

  name = '';
  selectedMonth = new Date().toISOString().substring(0, 7); // YYYY-MM format for input type month

  create() {
    const [year, month] = this.selectedMonth.split('-');
    const dateObj = new Date(parseInt(year), parseInt(month)-1, 1);

    let finalName = this.name.trim();
    if (!finalName) {
      const monthName = dateObj.toLocaleString('pt-PT', { month: 'long', year: 'numeric' });
      finalName = monthName.charAt(0).toUpperCase() + monthName.slice(1);
    }

    const newMonth: WorkMonth = {
      id: generateId(),
      month: dateObj.toISOString(),
      entries: [],
      notes: '',
      name: finalName
    };

    this.close.emit(newMonth);
  }
}