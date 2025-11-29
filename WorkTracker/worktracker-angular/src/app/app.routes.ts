import { Routes } from '@angular/router';
import { HomeComponent } from './pages/home/home.component';
import { MonthDetailComponent } from './pages/month-detail/month-detail.component';

export const routes: Routes = [
  {
    path: '',
    component: HomeComponent,
    children: [
      { path: 'month/:id', component: MonthDetailComponent },
      { path: '', component: MonthDetailComponent } // Estado vazio
    ]
  }
];