import { ComponentFixture, TestBed } from '@angular/core/testing';

import { DayEditorComponent } from './day-editor.component';

describe('DayEditorComponent', () => {
  let component: DayEditorComponent;
  let fixture: ComponentFixture<DayEditorComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [DayEditorComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(DayEditorComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
