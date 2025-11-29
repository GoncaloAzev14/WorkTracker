import { Component, Input, Output, EventEmitter, OnInit, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { WorkEntry, WorkPeriod, generateId } from '../../models/models';

@Component({
  selector: 'app-day-editor',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './day-editor.component.html',
  styleUrls: ['./day-editor.component.scss'],
  schemas: [CUSTOM_ELEMENTS_SCHEMA]
})
export class DayEditorComponent implements OnInit {
  @Input() entry!: WorkEntry;
  @Output() close = new EventEmitter<WorkEntry | null>();

  periods: WorkPeriod[] = [];

  ngOnInit() {
    this.periods = JSON.parse(JSON.stringify(this.entry.periods));
  }

  addPeriod() {
    let startHour = 9;
    if (this.periods.length > 0) {
      const last = this.periods[this.periods.length - 1];
      startHour = new Date(last.endTime).getHours();
      if (startHour < 23) startHour += 1;
    }
    const base = new Date(this.entry.day);
    const start = new Date(base.setHours(startHour,0,0,0)).toISOString();
    const end = new Date(base.setHours(startHour+1,0,0,0)).toISOString();
    this.periods.push({ id: generateId(), startTime: start, endTime: end });
  }

  removePeriod(index: number) { this.periods.splice(index, 1); }

  // Conversão ISO <-> Input Time (HH:mm)
  getTime(iso: string) { return new Date(iso).toTimeString().substring(0,5); }

  setTime(index: number, field: 'startTime'|'endTime', timeStr: string) {
    const [h, m] = timeStr.split(':').map(Number);
    const d = new Date(this.periods[index][field]);
    d.setHours(h, m);
    this.periods[index][field] = d.toISOString();
  }

  save() {
    this.close.emit({ ...this.entry, periods: this.periods });
  }
}