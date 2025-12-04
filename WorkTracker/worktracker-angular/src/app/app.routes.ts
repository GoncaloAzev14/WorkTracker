import { Routes } from '@angular/router';
import { HomeComponent } from './pages/home/home.component';
import { MonthDetailComponent } from './pages/month-detail/month-detail.component';
import { SheetListComponent } from './pages/sheet-list/sheet-list.component';
import { LoginComponent } from './pages/login/login.component';
import { SignUpComponent } from './pages/sign-up/sign-up.component';
import { authGuard, publicGuard } from './auth.guard';

export const routes: Routes = [
  { 
    path: 'login', 
    component: LoginComponent,
    canActivate: [publicGuard]
  },
  { 
    path: 'signup',
    component: SignUpComponent,
    canActivate: [publicGuard]
  },
  {
    path: '',
    component: HomeComponent,
    canActivate: [authGuard],
    children: [
      { path: '', component: SheetListComponent },
      { path: 'month/:id', component: MonthDetailComponent }
    ]
  }
];