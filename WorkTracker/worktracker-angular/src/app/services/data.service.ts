import { Injectable, inject, signal, effect } from '@angular/core';
import { Firestore, collection, collectionData, doc, setDoc, deleteDoc, docData } from '@angular/fire/firestore';
import { Auth, user } from '@angular/fire/auth';
import { Observable, of, Subject, switchMap, map } from 'rxjs';
import { toSignal } from '@angular/core/rxjs-interop';
import { WorkMonth } from '../models/models';

@Injectable({
  providedIn: 'root'
})
export class DataService {
  private firestore = inject(Firestore);
  private auth = inject(Auth);

  // --- EVENTOS DE UI (Funcionalidade Original) ---
  // Trigger para abrir o modal de criação a partir de outros componentes
  public createSheetRequest = new Subject<void>();

  // --- UTILIZADOR ---
  // Stream do utilizador logado
  private user$ = user(this.auth);

  // Helper para obter o UID atual de forma síncrona (se necessário)
  private get uid() { return this.auth.currentUser?.uid; }

  // --- DADOS (Sincronizados com a Cloud) ---

  // 1. MESES: Carrega automaticamente da coleção 'months' do utilizador
  public months = toSignal(
    this.user$.pipe(
      switchMap(u => {
        if (!u) return of([]); // Se não houver login, lista vazia
        // Caminho: users/{uid}/months
        const col = collection(this.firestore, `users/${u.uid}/months`);
        return collectionData(col, { idField: 'id' }) as Observable<WorkMonth[]>;
      })
    ),
    { initialValue: [] }
  );

  // 2. SETTINGS (Hourly Rate): Sinal gravável, mas sincronizado com a Cloud
  public hourlyRate = signal<number>(5.0);
  public activeMonthId = signal<string | null>(null);

  constructor() {
    // Efeito para carregar o Hourly Rate da cloud quando o user faz login
    this.user$.pipe(
      switchMap(u => {
        if (!u) return of(null);
        // Caminho: users/{uid}/settings/general
        const docRef = doc(this.firestore, `users/${u.uid}/settings/general`);
        return docData(docRef) as Observable<{ hourlyRate: number } | undefined>;
      })
    ).subscribe(settings => {
      if (settings && settings.hourlyRate) {
        // Atualiza o sinal local com o valor que veio da base de dados
        this.hourlyRate.set(settings.hourlyRate);
      }
    });
  }

  // --- MÉTODOS DE ESCRITA (Cloud Firestore) ---

  async addMonth(month: WorkMonth) {
    if (!this.uid) {
      console.error("ERRO: Tentativa de gravar sem utilizador logado!");
      return;
    }
    
    if (!month.hourlyRate) {
      month.hourlyRate = this.hourlyRate(); 
    }
    
    const path = `users/${this.uid}/months/${month.id}`;
    
    try {
      console.log("A tentar gravar em:", path);
      await setDoc(doc(this.firestore, path), month);
      console.log("Sucesso! Gravado na cloud.");
    } catch (error: any) {
      console.error("ERRO GRAVE AO GRAVAR:", error);
      // Este alerta vai dizer-te exatamente o que está mal (ex: Permission Denied)
      alert(`Erro ao gravar na Cloud: ${error.message || error}`);
      throw error;
    }
  }

  async updateMonth(updated: WorkMonth) {
    if (!this.uid) return;
    const path = `users/${this.uid}/months/${updated.id}`;
    await setDoc(doc(this.firestore, path), updated);
  }

  async deleteMonth(id: string) {
    if (!this.uid) return;
    const path = `users/${this.uid}/months/${id}`;
    await deleteDoc(doc(this.firestore, path));
  }

  async updateHourlyRate(rate: number) {
    // 1. Atualiza a UI imediatamente
    this.hourlyRate.set(rate);
    
    // 2. Persiste na Cloud
    if (!this.uid) return;
    const path = `users/${this.uid}/settings/general`;
    // 'merge: true' garante que não apagamos outros settings se existirem
    await setDoc(doc(this.firestore, path), { hourlyRate: rate }, { merge: true });
  }

  // --- IMPORTAÇÃO DE BACKUPS ---
  
  async importData(monthsData: WorkMonth[]) {
    if (!this.uid) return;
    
    // Cria uma Promise para cada mês e executa todas em paralelo
    const promises = monthsData.map(m => {
        const path = `users/${this.uid}/months/${m.id}`;
        return setDoc(doc(this.firestore, path), m);
    });

    await Promise.all(promises);
  }
}