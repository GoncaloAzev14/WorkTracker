export interface WorkPeriod {
  id: string;
  startTime: string; // ISO String
  endTime: string;   // ISO String
}

export interface WorkEntry {
  id: string;
  day: string; // ISO String
  periods: WorkPeriod[];
  isPaid: boolean;
}

export interface WorkMonth {
  id: string;
  month: string; // ISO String
  entries: WorkEntry[];
  hourlyRate?: number;
  notes: string;
  name: string;
  createdAt?: string; // ISO String — set once on creation, used for sorting
  deleted?: boolean;
  deletedAt?: string; // ISO String — set when deleted, used to enforce 30-day grace period
}

export const generateId = () => Math.random().toString(36).substring(2) + Date.now().toString(36);

export function entryHours(entry: WorkEntry): number {
  return entry.periods.reduce((total, p) => {
    const start = new Date(p.startTime).getTime();
    const end = new Date(p.endTime).getTime();
    return total + (Math.max(0, end - start) / (1000 * 60 * 60));
  }, 0);
}