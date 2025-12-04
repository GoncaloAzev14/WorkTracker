import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { Auth, authState } from '@angular/fire/auth';
import { map, take } from 'rxjs/operators';

export const authGuard = () => {
  const router = inject(Router);
  const auth = inject(Auth);

  return authState(auth).pipe(
    take(1),
    map(user => {
      // Se houver utilizador, deixa passar (true). Senão, redireciona para login.
      return user ? true : router.createUrlTree(['/login']);
    })
  );
};

export const publicGuard = () => {
  const router = inject(Router);
  const auth = inject(Auth);

  return authState(auth).pipe(
    take(1),
    map(user => {
      // Se JÁ houver utilizador, manda para a casa. Senão, deixa ver o login.
      return user ? router.createUrlTree(['/']) : true;
    })
  );
};