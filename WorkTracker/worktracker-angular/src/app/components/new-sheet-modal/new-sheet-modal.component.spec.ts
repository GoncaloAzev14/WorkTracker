import { ComponentFixture, TestBed } from '@angular/core/testing';

import { NewSheetModalComponent } from './new-sheet-modal.component';

describe('NewSheetModalComponent', () => {
  let component: NewSheetModalComponent;
  let fixture: ComponentFixture<NewSheetModalComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [NewSheetModalComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(NewSheetModalComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
