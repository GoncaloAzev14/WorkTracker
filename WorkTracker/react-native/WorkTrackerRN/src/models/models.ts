// src/models.ts
export type UUID = string;

export interface WorkPeriod {
  id: UUID;
  startTime: string; // ISO string
  endTime: string;   // ISO string
}

export interface WorkEntry {
  id: UUID;
  day: string; // ISO date (only date part usually)
  periods: WorkPeriod[];
  isPaid: boolean;
}

export interface WorkMonth {
  id: UUID;
  month: string; // ISO date representing 1st of month
  entries: WorkEntry[];
  notes: string;
  name: string;
}

export function generateId(): string {
  return Math.random().toString(36).slice(2) + Date.now().toString(36);
}

/* Helpers (calculations similar to Swift) */
export function periodWorkedHours(p: WorkPeriod): number {
  const s = new Date(p.startTime).getTime();
  const e = new Date(p.endTime).getTime();
  if (e <= s) return 0;
  return (e - s) / 3600_000;
}

export function entryWorkedHours(entry: WorkEntry): number {
  return entry.periods.reduce((acc, p) => acc + periodWorkedHours(p), 0);
}

export function entryCalculatedPay(entry: WorkEntry, hourlyRate: number) {
  return entryWorkedHours(entry) * hourlyRate;
}

export function monthTotalEstimatedPay(month: WorkMonth, hourlyRate: number) {
  return month.entries.reduce((acc, e) => acc + entryCalculatedPay(e, hourlyRate), 0);
}

export function monthTotalActualPay(month: WorkMonth, hourlyRate: number) {
  return month.entries.filter(e => e.isPaid).reduce((acc,e) => acc + entryCalculatedPay(e, hourlyRate), 0);
}

/* defaultPeriod similar heuristics to Swift's defaultPeriod(for:) */

export function defaultPeriodFor(date: Date): WorkPeriod {
    const weekday = date.getDay(); // 0 Sunday
    let startHour = 8, endHour = 12;
    if (weekday === 1 || weekday === 3 || weekday === 5) { startHour = 17; endHour = 20; }
    else if (weekday === 0) { startHour = 0; endHour = 0; }
    const s = new Date(date); s.setHours(startHour,0,0,0);
    const e = new Date(date); e.setHours(endHour,0,0,0);
    return { id: generateId(), startTime: s.toISOString(), endTime: e.toISOString() };
  }

export function cryptoRandomId() {
  // cross-platform simple id:
  return Math.random().toString(36).slice(2) + Date.now().toString(36);
}
