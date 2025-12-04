import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { Auth, signInWithEmailAndPassword } from '@angular/fire/auth';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="login-container">
      <div class="card">
        <h1>Bem-vindo</h1>
        <input type="email" [(ngModel)]="email" placeholder="Email" class="input">
        <input type="password" [(ngModel)]="password" placeholder="Password" class="input">
        <button (click)="login()" class="btn">Entrar</button>
        <p class="error" *ngIf="error">{{ error }}</p>
      </div>
    </div>
  `,
  styles: [`
    .login-container { height: 100vh; display: flex; align-items: center; justify-content: center; background: #f2f2f7; }
    .card { background: white; padding: 30px; border-radius: 16px; width: 90%; max-width: 350px; text-align: center; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
    .input { width: 100%; padding: 12px; margin-bottom: 15px; border: 1px solid #c6c6c8; border-radius: 8px; font-size: 16px; }
    .btn { width: 100%; padding: 12px; background: #007aff; color: white; border: none; border-radius: 8px; font-weight: bold; cursor: pointer; }
    .error { color: #ff3b30; margin-top: 10px; font-size: 14px; }
  `]
})
export class LoginComponent {
  email = '';
  password = '';
  error = '';
  
  private auth = inject(Auth);
  private router = inject(Router);

  async login() {
    try {
      await signInWithEmailAndPassword(this.auth, this.email, this.password);
      this.router.navigate(['/']); // Vai para a home após login
    } catch (e: any) {
      this.error = 'Erro ao entrar: ' + e.message;
    }
  }
}