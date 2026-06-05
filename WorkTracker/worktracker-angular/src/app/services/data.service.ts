import { Injectable, inject, signal, computed } from '@angular/core';
import { Firestore, collection, collectionData, doc, setDoc, deleteDoc, docData } from '@angular/fire/firestore';
import { Auth, user } from '@angular/fire/auth';
import { Observable, of, Subject, switchMap } from 'rxjs';
import { toSignal } from '@angular/core/rxjs-interop';
import { WorkMonth } from '../models/models';

const TRASH_GRACE_DAYS = 30;

@Injectable({
  providedIn: 'root'
})
export class DataService {
  private firestore = inject(Firestore);
  private auth = inject(Auth);

  public createSheetRequest = new Subject<void>();

  private user$ = user(this.auth);
  private get uid() { return this.auth.currentUser?.uid; }

  // All documents from Firestore (including soft-deleted ones)
  private allMonths = toSignal(
    this.user$.pipe(
      switchMap((u): Observable<WorkMonth[]> => {
        if (!u) return of([]);
        const col = collection(this.firestore, `users/${u.uid}/months`);
        return collectionData(col, { idField: 'id' }) as Observable<WorkMonth[]>;
      })
    ),
    { initialValue: [] as WorkMonth[] }
  );

  // Active months visible to the user (not deleted)
  public months = computed(() =>
    (this.allMonths() ?? []).filter(m => !m.deleted)
  );

  // Soft-deleted months within the 30-day grace window
  public deletedMonths = computed(() => {
    const cutoff = Date.now() - TRASH_GRACE_DAYS * 24 * 60 * 60 * 1000;
    return (this.allMonths() ?? []).filter(
      m => m.deleted && m.deletedAt && new Date(m.deletedAt).getTime() > cutoff
    );
  });

  public hourlyRate = signal<number>(5.0);
  public activeMonthId = signal<string | null>(null);

  constructor() {
    this.user$.pipe(
      switchMap(u => {
        if (!u) return of(null);
        const docRef = doc(this.firestore, `users/${u.uid}/settings/general`);
        return docData(docRef) as Observable<{ hourlyRate: number } | undefined>;
      })
    ).subscribe((settings: { hourlyRate: number } | undefined | null) => {
      if (settings && settings.hourlyRate) {
        this.hourlyRate.set(settings.hourlyRate);
      }
    });
  }

  // --- WRITE METHODS ---

  async addMonth(month: WorkMonth) {
    if (!this.uid) {
      console.error("ERRO: Tentativa de gravar sem utilizador logado!");
      return;
    }
    if (!month.hourlyRate) {
      month.hourlyRate = this.hourlyRate();
    }
    if (!month.createdAt) {
      month.createdAt = new Date().toISOString();
    }
    const path = `users/${this.uid}/months/${month.id}`;
    try {
      await setDoc(doc(this.firestore, path), month);
    } catch (error: any) {
      console.error("ERRO GRAVE AO GRAVAR:", error);
      alert(`Erro ao gravar na Cloud: ${error.message || error}`);
      throw error;
    }
  }

  async updateMonth(updated: WorkMonth) {
    if (!this.uid) return;
    const path = `users/${this.uid}/months/${updated.id}`;
    await setDoc(doc(this.firestore, path), updated);
  }

  // Soft delete — marks the sheet as deleted but keeps it in Firestore
  async softDeleteMonth(id: string) {
    if (!this.uid) return;
    const month = (this.allMonths() ?? []).find((m: WorkMonth) => m.id === id);
    if (!month) return;
    const path = `users/${this.uid}/months/${id}`;
    await setDoc(doc(this.firestore, path), {
      ...month,
      deleted: true,
      deletedAt: new Date().toISOString()
    });
  }

  // Restore a soft-deleted sheet
  async recoverMonth(id: string) {
    if (!this.uid) return;
    const month = (this.allMonths() ?? []).find((m: WorkMonth) => m.id === id);
    if (!month) return;
    const path = `users/${this.uid}/months/${id}`;
    const { deleted, deletedAt, ...rest } = month;
    await setDoc(doc(this.firestore, path), rest);
  }

  // Hard delete — permanently removes the document from Firestore
  async permanentlyDeleteMonth(id: string) {
    if (!this.uid) return;
    const path = `users/${this.uid}/months/${id}`;
    await deleteDoc(doc(this.firestore, path));
  }

  async updateHourlyRate(rate: number) {
    this.hourlyRate.set(rate);
    if (!this.uid) return;
    const path = `users/${this.uid}/settings/general`;
    await setDoc(doc(this.firestore, path), { hourlyRate: rate }, { merge: true });
  }

  async importData(monthsData: WorkMonth[]) {
    if (!this.uid) return;
    const promises = monthsData.map(m => {
      const path = `users/${this.uid}/months/${m.id}`;
      return setDoc(doc(this.firestore, path), m);
    });
    await Promise.all(promises);
  }
}
