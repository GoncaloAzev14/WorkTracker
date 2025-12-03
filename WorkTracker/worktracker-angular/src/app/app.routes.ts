import { Routes } from '@angular/router';
import { HomeComponent } from './pages/home/home.component';
import { MonthDetailComponent } from './pages/month-detail/month-detail.component';
import { SheetListComponent } from './pages/sheet-list/sheet-list.component';

export const routes: Routes = [
  {
    path: '',
    component: HomeComponent,
    children: [
      { path: '', component: SheetListComponent },
      { path: 'month/:id', component: MonthDetailComponent }
    ]
  }
];