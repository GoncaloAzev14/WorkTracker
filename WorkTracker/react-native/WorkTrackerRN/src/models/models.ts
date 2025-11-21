export type UUID = string;

export interface WorkPeriod {
  id: UUID;
  startTime: string; // ISO string
  endTime: string;   // ISO string
}

export interface WorkEntry {
  id: UUID;
  day: string; // ISO (date-only)
  periods: WorkPeriod[];
  isPaid: boolean;
}

export interface WorkMonth {
  id: UUID;
  month: string; // ISO date representing first of month
  entries: WorkEntry[];
  notes: string;
  name: string;
}

export function generateId(): string {
  return Math.random().toString(36).slice(2) + Date.now().toString(36);
}

export function startOfMonth(year: number, month1to12: number): string {
  const d = new Date(year, month1to12 - 1, 1);
  d.setHours(0,0,0,0);
  return d.toISOString();
}

export function monthDisplayName(isoMonth: string): string {
  const d = new Date(isoMonth);
  return d.toLocaleString('pt-PT', { month: 'long', year: 'numeric' });
}

export function defaultPeriodFor(date: Date): WorkPeriod {
  const weekday = date.getDay(); // 0 Sunday
  let startHour = 17, endHour = 20;
  if (weekday === 6) { startHour = 8; endHour = 12; }
  else if (weekday === 0) { startHour = 0; endHour = 0; }
  const s = new Date(date); s.setHours(startHour,0,0,0);
  const e = new Date(date); e.setHours(endHour,0,0,0);
  return { id: generateId(), startTime: s.toISOString(), endTime: e.toISOString() };
}

export function periodHours(p: WorkPeriod) {
  const s = new Date(p.startTime).getTime();
  const e = new Date(p.endTime).getTime();
  return Math.max(0, (e - s) / 3600000);
}

export function entryHours(entry: WorkEntry) {
  return entry.periods.reduce((s,p) => s + periodHours(p), 0);
}

export function entryPay(entry: WorkEntry, hourlyRate: number) {
  return entryHours(entry) * hourlyRate;
}
