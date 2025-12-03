import { Injectable } from '@angular/core';
import { jsPDF } from 'jspdf';
import autoTable from 'jspdf-autotable';
import { WorkMonth, entryHours } from '../models/models';

@Injectable({
  providedIn: 'root'
})
export class PdfService {

  async exportMonth(month: WorkMonth, hourlyRate: number) {
    const doc = new jsPDF();

    // Cabeçalho
    doc.setFontSize(20);
    doc.text(month.name, 14, 20);

    doc.setFontSize(12);
    doc.setTextColor(100);
    const dateStr = new Date(month.month).toLocaleString('pt-PT', { month: 'long', year: 'numeric' });
    doc.text(dateStr.charAt(0).toUpperCase() + dateStr.slice(1), 14, 28);

    // Resumo
    const totalHours = month.entries.reduce((sum, e) => sum + entryHours(e), 0);
    const totalPay = totalHours * hourlyRate;

    doc.setFontSize(10);
    doc.setTextColor(0);
    doc.text(`Total Horas: ${totalHours.toFixed(0)}h`, 14, 40);
    doc.text(`Total a Receber: ${totalPay.toFixed(0)} €`, 14, 46);
    doc.text(`Taxa: ${hourlyRate.toFixed(0)} €/h`, 80, 40);

    // Tabela
    const rows = month.entries
      .sort((a, b) => new Date(a.day).getTime() - new Date(b.day).getTime())
      .map(entry => {
        const hours = entryHours(entry);
        const pay = hours * hourlyRate;
        const periods = entry.periods.map(p => {
          const s = new Date(p.startTime).toLocaleTimeString('pt-PT', { hour: '2-digit', minute: '2-digit' });
          const e = new Date(p.endTime).toLocaleTimeString('pt-PT', { hour: '2-digit', minute: '2-digit' });
          return `${s}-${e}`;
        }).join('\n');

        return [
          new Date(entry.day).toLocaleDateString('pt-PT', { day: '2-digit', month: 'long' }),
          periods,
          `${hours.toFixed(0)}h`,
          `${pay.toFixed(0)} €`
        ];
      });

    autoTable(doc, {
      startY: 55,
      head: [['Data', 'Horário', 'Horas', 'Valor']],
      body: rows,
      theme: 'grid',
      headStyles: { fillColor: [66, 139, 202], halign: 'center' },
      styles: { fontSize: 10, cellPadding: 3 },
      columnStyles: {
        0: { cellWidth: 25, halign: 'center', valign: 'middle' },
        1: { cellWidth: 60, halign: 'center', valign: 'middle' },
        2: { cellWidth: 20, halign: 'center', valign: 'middle' },
        3: { cellWidth: 25, halign: 'center', valign: 'middle' },
      }
    });

    // Notas
    if (month.notes) {
      const finalY = (doc as any).lastAutoTable.finalY + 10;
      doc.setFontSize(10);
      doc.setTextColor(0);
      doc.text('Notas:', 14, finalY);
      doc.setFontSize(9);
      doc.setTextColor(80);
      doc.text(month.notes, 14, finalY + 6, { maxWidth: 180 });
    }

    // Guardar
    doc.save(`${month.name.replace(/[^a-z0-9]/gi, '_')}.pdf`);
  }
}