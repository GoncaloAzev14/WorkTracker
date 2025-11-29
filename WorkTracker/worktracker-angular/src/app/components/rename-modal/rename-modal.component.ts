import { Component, Input, Output, EventEmitter, OnInit, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { WorkMonth } from '../../models/models';

@Component({
  selector: 'app-rename-modal',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './rename-modal.component.html',
  schemas: [CUSTOM_ELEMENTS_SCHEMA]
})
export class RenameModalComponent implements OnInit {
  @Input() month!: WorkMonth;
  @Output() close = new EventEmitter<{action: 'rename'|'delete'|'cancel', data?: any}>();

  name = '';

  ngOnInit() { this.name = this.month.name; }

  save() { this.close.emit({ action: 'rename', data: this.name }); }
  remove() {
    if(confirm('Tem a certeza?')) this.close.emit({ action: 'delete' });
  }
}