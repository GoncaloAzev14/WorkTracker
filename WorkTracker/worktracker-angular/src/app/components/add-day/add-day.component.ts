import { Component, Input, Output, EventEmitter, OnInit, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { CommonModule } from '@angular/common';
import { WorkMonth } from '../../models/models';

@Component({
  selector: 'app-add-day',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './add-day.component.html',
  styleUrls: ['./add-day.component.scss'],
  schemas: [CUSTOM_ELEMENTS_SCHEMA]
})
export class AddDayComponent implements OnInit {
  @Input() month!: WorkMonth;
  @Output() close = new EventEmitter<string | null>();

  nextDay: string | null = null;
  missingDays: string[] = [];

  ngOnInit() {
    this.calculateDates();
  }

  private calculateDates() {
    const entries = this.month.entries.sort((a, b) => new Date(a.day).getTime() - new Date(b.day).getTime());
    const monthStart = new Date(this.month.month);

    if (entries.length === 0) {
      this.nextDay = monthStart.toISOString();
    } else {
      const last = new Date(entries[entries.length - 1].day);
      last.setDate(last.getDate() + 1);
      if (last.getMonth() === monthStart.getMonth()) {
        this.nextDay = last.toISOString();
      }
    }

    if (entries.length > 1) {
      const first = new Date(entries[0].day);
      const last = new Date(entries[entries.length - 1].day);
      for (let d = new Date(first); d < last; d.setDate(d.getDate() + 1)) {
        const iso = d.toISOString();
        const exists = entries.some(e => new Date(e.day).toDateString() === d.toDateString());
        if (!exists) this.missingDays.push(iso);
      }
    }
  }
}