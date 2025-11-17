// src/utils/PDFGenerator.ts
import { PDFDocument, StandardFonts, rgb } from 'pdf-lib';
import Share from 'react-native-share';
import { WorkMonth, entryWorkedHours, entryCalculatedPay } from '../models/models';

export async function generateMonthPDF(month: WorkMonth, hourlyRate: number) {
  
  const pdf = await PDFDocument.create();
  const page = pdf.addPage([595.28, 841.89]); // A4
  const font = await pdf.embedFont(StandardFonts.Helvetica);

  const { width } = page.getSize();

  let y = 800;

  function text(str: string, x: number, yPos: number, size = 12) {
    page.drawText(str, { x, y: yPos, size, font, color: rgb(0,0,0) });
  }

  // HEADER
  text(`Folha: ${month.name}`, 40, y, 18); y -= 24;
  text(`Mês: ${new Date(month.month).toLocaleString('pt-PT', {month:'long', year:'numeric'})}`, 40, y, 12);
  y -= 40;

  // TABLE HEADER
  text("Dia", 40, y);
  text("Horas", 180, y);
  text("Valor (€)", 260, y);
  text("Pago", 360, y);
  y -= 20;

  // ENTRIES
  const sorted = [...month.entries]
    .sort((a,b) => new Date(a.day).getTime() - new Date(b.day).getTime());

  let totalPay = 0;

  sorted.forEach(entry => {
    const hours = entryWorkedHours(entry);
    const pay = entryCalculatedPay(entry, hourlyRate);
    totalPay += pay;

    text(
      new Date(entry.day).toLocaleDateString('pt-PT',{ day:'2-digit', month:'2-digit' }),
      40,
      y
    );
    text(hours.toFixed(1), 180, y);
    text(pay.toFixed(2), 260, y);
    text(entry.isPaid ? "Sim" : "Não", 360, y);

    y -= 20;
    if (y < 60) {
      // new page
      y = 800;
    }
  });

  y -= 20;
  text(`Total: €${totalPay.toFixed(2)}`, 40, y, 14);

  const pdfBytes = await pdf.save();

  // SHARE
  await Share.open({
    title: "Exportar PDF",
    saveToFiles: true,
    url: `data:application/pdf;base64,${Buffer.from(pdfBytes).toString('base64')}`,
    type: 'application/pdf'
  });
}
