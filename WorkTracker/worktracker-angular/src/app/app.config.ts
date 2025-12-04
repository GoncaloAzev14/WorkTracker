import { ApplicationConfig, provideZoneChangeDetection, LOCALE_ID, isDevMode } from '@angular/core';
import { registerLocaleData } from '@angular/common';
import localePt from '@angular/common/locales/pt-PT';
import { provideServiceWorker } from '@angular/service-worker';
import { provideRouter, withHashLocation } from '@angular/router';
import { routes } from './app.routes';
import { initializeApp, provideFirebaseApp } from '@angular/fire/app';
import { getAuth, provideAuth } from '@angular/fire/auth';
import { getFirestore, provideFirestore } from '@angular/fire/firestore';

// Registar os dados de localização para pt-PT
registerLocaleData(localePt);

export const appConfig: ApplicationConfig = {
  providers: [
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(routes, withHashLocation()),
    { provide: LOCALE_ID, useValue: 'pt-PT' },
    provideServiceWorker('ngsw-worker.js', {
      enabled: !isDevMode(),
      registrationStrategy: 'registerWhenStable:30000'
    }), provideFirebaseApp(() => initializeApp({ 
      projectId: "worktracker-52d5a", 
      appId: "1:992252690646:web:6cb48b7655a6336c8e8977", 
      storageBucket: "worktracker-52d5a.firebasestorage.app", 
      apiKey: "AIzaSyCRGk5Ks1y36KwZmhqzacrUzY8TbDidIfA", 
      authDomain: "worktracker-52d5a.firebaseapp.com", 
      messagingSenderId: "992252690646", 
      measurementId: "G-5ZBSFY077F" 
    })), provideAuth(() => getAuth()), provideFirestore(() => getFirestore())
  ]
};