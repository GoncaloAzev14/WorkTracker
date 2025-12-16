import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { Auth, createUserWithEmailAndPassword } from '@angular/fire/auth';
import { CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';

@Component({
  selector: 'app-sign-up',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
  templateUrl: './sign-up.component.html',
  styleUrl: './sign-up.component.scss'
})
export class SignUpComponent {
  email = '';
  password = '';
  error = '';

  private auth = inject(Auth);
  private router = inject(Router);

  async signup() {
    this.error = ''; 
    if (!this.email || !this.password) {
      this.error = 'Por favor preencha todos os campos.';
      return;
    }

    try {
      await createUserWithEmailAndPassword(this.auth, this.email, this.password);

      this.router.navigate(['/']); 
    } catch (e: any) {
      if (e.code === 'auth/email-already-in-use') {
        this.error = 'Este email já está registado.';
      } else if (e.code === 'auth/weak-password') {
        this.error = 'A password deve ter pelo menos 6 caracteres.';
      } else {
        this.error = 'Erro ao criar conta: ' + e.message;
      }
    }
  }
}