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

  // Validation state
  periodErrors = new Set<number>(); // indices of periods where end <= start
  hasOverlapError = false;

  get hasErrors(): boolean {
    return this.periodErrors.size > 0 || this.hasOverlapError;
  }

  ngOnInit() {
    this.periods = JSON.parse(JSON.stringify(this.entry.periods));
    this.validatePeriods();
  }

  addPeriod() {
    let startHour = 9;
    if (this.periods.length > 0) {
      const last = this.periods[this.periods.length - 1];
      startHour = new Date(last.endTime).getHours();
      if (startHour < 23) startHour += 1;
    }
    const base = new Date(this.entry.day);
    const start = new Date(base.setHours(startHour, 0, 0, 0)).toISOString();
    const end   = new Date(base.setHours(Math.min(startHour + 1, 23), 0, 0, 0)).toISOString();
    this.periods.push({ id: generateId(), startTime: start, endTime: end });
    this.validatePeriods();
  }

  removePeriod(index: number) {
    this.periods.splice(index, 1);
    this.validatePeriods();
  }

  getTime(iso: string) { return new Date(iso).toTimeString().substring(0, 5); }

  setTime(index: number, field: 'startTime' | 'endTime', timeStr: string) {
    const [h, m] = timeStr.split(':').map(Number);
    const d = new Date(this.periods[index][field]);
    d.setHours(h, m, 0, 0);
    this.periods[index][field] = d.toISOString();
    this.validatePeriods();
  }

  // ─── Validation ────────────────────────────────────────────────────────────

  private validatePeriods() {
    // 1. End must be strictly after start on each period
    this.periodErrors = new Set<number>();
    this.periods.forEach((p, i) => {
      if (new Date(p.endTime).getTime() <= new Date(p.startTime).getTime()) {
        this.periodErrors.add(i);
      }
    });

    // 2. No two periods may overlap
    this.hasOverlapError = false;
    outer: for (let i = 0; i < this.periods.length; i++) {
      for (let j = i + 1; j < this.periods.length; j++) {
        const aStart = new Date(this.periods[i].startTime).getTime();
        const aEnd   = new Date(this.periods[i].endTime).getTime();
        const bStart = new Date(this.periods[j].startTime).getTime();
        const bEnd   = new Date(this.periods[j].endTime).getTime();
        if (aStart < bEnd && aEnd > bStart) {
          this.hasOverlapError = true;
          break outer;
        }
      }
    }
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  save() {
    if (this.hasErrors) return;
    this.close.emit({ ...this.entry, periods: this.periods });
  }
}
