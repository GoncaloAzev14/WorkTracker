// src/utils/PDFGenerator.ts
import * as Print from 'expo-print';
import * as Sharing from 'expo-sharing';
import { WorkMonth, WorkEntry, entryHours, monthDisplayName } from '../models/models';

export async function exportMonthToPDF(month: WorkMonth, hourlyRate: number) {
  try {
    const html = generateHTML(month, hourlyRate);
    
    // Gerar o ficheiro PDF
    const { uri } = await Print.printToFileAsync({
      html: html,
      base64: false
    });

    // Partilhar o ficheiro
    await Sharing.shareAsync(uri, {
      UTI: '.pdf',
      mimeType: 'application/pdf',
      dialogTitle: `Exportar ${month.name}`
    });

  } catch (error) {
    console.error("Erro ao gerar PDF:", error);
  }
}

function generateHTML(month: WorkMonth, hourlyRate: number): string {
  const totalHours = month.entries.reduce((sum, e) => sum + entryHours(e), 0);
  const paidHours = month.entries.filter(e => e.isPaid).reduce((sum, e) => sum + entryHours(e), 0);
  const totalPay = totalHours * hourlyRate;
  const paidPay = paidHours * hourlyRate;

  // Ordenar entradas por dia
  const sortedEntries = [...month.entries].sort((a, b) => new Date(a.day).getTime() - new Date(b.day).getTime());

  const rows = sortedEntries.map(entry => {
    const hours = entryHours(entry);
    const pay = hours * hourlyRate;
    const dateStr = new Date(entry.day).toLocaleDateString('pt-PT', { day: '2-digit', month: 'short' });
    const periodsStr = entry.periods.map(p => {
      const s = new Date(p.startTime).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
      const e = new Date(p.endTime).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
      return `${s}-${e}`;
    }).join('<br>');
    
    const rowColor = entry.isPaid ? '#e8f5e9' : '#fff'; // Verde claro se pago
    const payColor = entry.isPaid ? '#2e7d32' : '#d32f2f';

    return `
      <tr style="background-color: ${rowColor};">
        <td style="padding: 8px; border-bottom: 1px solid #eee;"><b>${dateStr}</b></td>
        <td style="padding: 8px; border-bottom: 1px solid #eee;">${periodsStr}</td>
        <td style="padding: 8px; border-bottom: 1px solid #eee; text-align: center;">${hours.toFixed(1)}h</td>
        <td style="padding: 8px; border-bottom: 1px solid #eee; text-align: right; color: ${payColor}; font-weight: bold;">€${pay.toFixed(2)}</td>
      </tr>
    `;
  }).join('');

  return `
    <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no" />
        <style>
          body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; padding: 20px; color: #333; }
          h1 { margin-bottom: 5px; color: #000; }
          h2 { margin-top: 0; color: #666; font-weight: normal; font-size: 18px; border-bottom: 1px solid #ccc; padding-bottom: 10px; }
          .summary { display: flex; justify-content: space-between; margin-bottom: 20px; background: #f9f9f9; padding: 15px; border-radius: 8px; }
          .summary-item { text-align: center; }
          .summary-label { font-size: 10px; text-transform: uppercase; color: #888; letter-spacing: 1px; }
          .summary-value { font-size: 18px; font-weight: bold; margin-top: 5px; }
          table { width: 100%; border-collapse: collapse; margin-top: 10px; }
          th { text-align: left; font-size: 12px; color: #888; padding: 8px; border-bottom: 2px solid #eee; }
          .notes { margin-top: 30px; padding: 15px; background: #fffbe6; border: 1px solid #ffe58f; border-radius: 8px; }
          .footer { margin-top: 50px; text-align: center; font-size: 10px; color: #ccc; }
        </style>
      </head>
      <body>
        <h1>${month.name}</h1>
        <h2>${monthDisplayName(month.month)}</h2>

        <div class="summary">
          <div class="summary-item">
            <div class="summary-label">Total Horas</div>
            <div class="summary-value">${totalHours.toFixed(1)}h</div>
          </div>
          <div class="summary-item">
            <div class="summary-label">Taxa Hora</div>
            <div class="summary-value">€${hourlyRate.toFixed(2)}</div>
          </div>
          <div class="summary-item">
            <div class="summary-label">Total (Est.)</div>
            <div class="summary-value">€${totalPay.toFixed(2)}</div>
          </div>
          <div class="summary-item">
            <div class="summary-label">Total (Pago)</div>
            <div class="summary-value" style="color: #2e7d32;">€${paidPay.toFixed(2)}</div>
          </div>
        </div>

        <table>
          <thead>
            <tr>
              <th width="20%">DATA</th>
              <th width="40%">HORÁRIO</th>
              <th width="20%" style="text-align: center;">HORAS</th>
              <th width="20%" style="text-align: right;">VALOR</th>
            </tr>
          </thead>
          <tbody>
            ${rows}
          </tbody>
        </table>

        ${month.notes ? `
          <div class="notes">
            <strong>Notas:</strong><br>
            ${month.notes.replace(/\n/g, '<br>')}
          </div>
        ` : ''}

        <div class="footer">
          Gerado por WorkTracker • ${new Date().toLocaleDateString('pt-PT')}
        </div>
      </body>
    </html>
  `;
}