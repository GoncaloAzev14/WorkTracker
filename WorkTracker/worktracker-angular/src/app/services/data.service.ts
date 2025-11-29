import { Injectable, signal, effect, PLATFORM_ID, inject } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { WorkMonth } from '../models/models';

@Injectable({
  providedIn: 'root'
})
export class DataService {
  public months = signal<WorkMonth[]>([]);
  public hourlyRate = signal<number>(5.0);

  private MONTHS_KEY = 'worktracker_months';
  private SETTINGS_KEY = 'worktracker_settings';

  // Injeta o ID da plataforma para saber se estamos no Browser ou Servidor
  private platformId = inject(PLATFORM_ID);

  constructor() {
    // Só carrega dados se estiver no Browser
    if (isPlatformBrowser(this.platformId)) {
      this.loadData();
    }

    // Efeitos: só gravam se estiver no Browser
    effect(() => {
      if (isPlatformBrowser(this.platformId)) {
        localStorage.setItem(this.MONTHS_KEY, JSON.stringify(this.months()));
      }
    });

    effect(() => {
      if (isPlatformBrowser(this.platformId)) {
        localStorage.setItem(this.SETTINGS_KEY, JSON.stringify({ hourlyRate: this.hourlyRate() }));
      }
    });
  }

  private loadData() {
    // Verificação extra de segurança (embora o construtor já proteja)
    if (!isPlatformBrowser(this.platformId)) return;

    const monthsData = localStorage.getItem(this.MONTHS_KEY);
    if (monthsData) {
      try {
        this.months.set(JSON.parse(monthsData));
      } catch (e) { console.error('Error loading months', e); }
    }

    const settingsData = localStorage.getItem(this.SETTINGS_KEY);
    if (settingsData) {
      try {
        this.hourlyRate.set(JSON.parse(settingsData).hourlyRate || 5.0);
      } catch (e) { console.error('Error loading settings', e); }
    }
  }

  addMonth(month: WorkMonth) {
    this.months.update(curr => [...curr, month]);
  }

  updateMonth(updated: WorkMonth) {
    this.months.update(curr => curr.map(m => m.id === updated.id ? updated : m));
  }

  deleteMonth(id: string) {
    this.months.update(curr => curr.filter(m => m.id !== id));
  }

  updateHourlyRate(rate: number) {
    this.hourlyRate.set(rate);
  }
}