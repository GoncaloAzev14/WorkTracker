//
//  PDFGenerator1.swift
//  WorkTracker
//
//  Created by Gonçalo Azevedo on 31/07/2025.
//

import SwiftUI
import PDFKit

// MARK: - PDF Generator
class PDFGenerator {
    static func generatePDF(for workMonth: WorkMonth, hourlyRate: Double) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Work Tracker",
            kCGPDFContextTitle: workMonth.name
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            drawPDFContent(context: context, workMonth: workMonth, hourlyRate: hourlyRate, pageRect: pageRect)
        }
        
        return data
    }
    
    private static func drawPDFContent(context: UIGraphicsPDFRendererContext, workMonth: WorkMonth, hourlyRate: Double, pageRect: CGRect) {
        let margin: CGFloat = 50
        let sortedEntries = workMonth.sortedEntries
        var currentEntryIndex = 0
        var isFirstPage = true
        
        while currentEntryIndex < sortedEntries.count {
            // Begin new page
            context.beginPage()
            let cgContext = context.cgContext
            
            var yPosition: CGFloat = margin
            
            // Draw header on every page
            yPosition = drawHeader(cgContext: cgContext, workMonth: workMonth, hourlyRate: hourlyRate, pageRect: pageRect, yPosition: yPosition, isFirstPage: isFirstPage)
            
            // Draw table header
            yPosition = drawTableHeader(cgContext: cgContext, pageRect: pageRect, yPosition: yPosition)
            let tableStartY = yPosition - 25
            
            // Draw entries for this page
            let entriesDrawn = drawEntries(
                cgContext: cgContext,
                entries: sortedEntries,
                startIndex: currentEntryIndex,
                hourlyRate: hourlyRate,
                pageRect: pageRect,
                yPosition: &yPosition,
                tableStartY: tableStartY
            )
            
            // Draw table borders
            drawTableBorders(cgContext: cgContext, pageRect: pageRect, tableStartY: tableStartY, yPosition: yPosition)
            
            // Draw footer
            drawFooter(cgContext: cgContext, pageRect: pageRect)
            
            // Update index for next page
            currentEntryIndex += entriesDrawn
            isFirstPage = false
            
            // If we've drawn all entries, add notes to the last page if there's space
            if currentEntryIndex >= sortedEntries.count {
                drawNotes(cgContext: cgContext, workMonth: workMonth, pageRect: pageRect, yPosition: &yPosition)
            }
        }
    }
    
    // MARK: - Drawing Helper Functions
    
    private static func drawHeader(cgContext: CGContext, workMonth: WorkMonth, hourlyRate: Double, pageRect: CGRect, yPosition: CGFloat, isFirstPage: Bool) -> CGFloat {
        let margin: CGFloat = 50
        var currentY = yPosition
        
        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.black
        ]
        
        let title = workMonth.name
        title.draw(at: CGPoint(x: margin, y: currentY), withAttributes: titleAttributes)
        currentY += 40
        
        // Month info
        let monthAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.gray
        ]
        
        workMonth.monthName.draw(at: CGPoint(x: margin, y: currentY), withAttributes: monthAttributes)
        currentY += 30
        
        // Summary section (only on first page)
        if isFirstPage {
            currentY = drawSummary(cgContext: cgContext, workMonth: workMonth, hourlyRate: hourlyRate, pageRect: pageRect, yPosition: currentY)
        }
        
        return currentY
    }
    
    private static func drawSummary(cgContext: CGContext, workMonth: WorkMonth, hourlyRate: Double, pageRect: CGRect, yPosition: CGFloat) -> CGFloat {
        let margin: CGFloat = 50
        var currentY = yPosition
        
        let summaryAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor.black
        ]
        
        let regularAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        
        // Draw summary box
        let summaryRect = CGRect(x: margin, y: currentY, width: pageRect.width - 2*margin, height: 100)
        cgContext.setStrokeColor(UIColor.lightGray.cgColor)
        cgContext.setLineWidth(1)
        cgContext.stroke(summaryRect)
        
        currentY += 15
        
        // Summary content
        "Resumo".draw(at: CGPoint(x: margin + 10, y: currentY), withAttributes: summaryAttributes)
        currentY += 20
        
        let totalHours = String(format: "Total de Horas: %.1f", workMonth.totalHours)
        totalHours.draw(at: CGPoint(x: margin + 10, y: currentY), withAttributes: regularAttributes)
        
        let paidHours = String(format: "Horas Pagas: %.1f", workMonth.totalPaidHours)
        paidHours.draw(at: CGPoint(x: margin + 200, y: currentY), withAttributes: regularAttributes)
        currentY += 15
        
        let hourlyRateText = String(format: "Taxa Horária: €%.2f", hourlyRate)
        hourlyRateText.draw(at: CGPoint(x: margin + 10, y: currentY), withAttributes: regularAttributes)
        
        let totalPay = String(format: "Total Pago: €%.2f", workMonth.totalActualPay(hourlyRate: hourlyRate))
        totalPay.draw(at: CGPoint(x: margin + 200, y: currentY), withAttributes: regularAttributes)
        currentY += 15
        
        let estimatedPay = String(format: "Total Estimado: €%.2f", workMonth.totalEstimatedPay(hourlyRate: hourlyRate))
        estimatedPay.draw(at: CGPoint(x: margin + 10, y: currentY), withAttributes: regularAttributes)
        currentY += 35
        
        return currentY
    }
    
    private static func drawTableHeader(cgContext: CGContext, pageRect: CGRect, yPosition: CGFloat) -> CGFloat {
        let margin: CGFloat = 50
        var currentY = yPosition
        
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        
        // Calculate column widths
        let dateColumnWidth: CGFloat = 80
        let timeColumnWidth: CGFloat = 280
        let hoursColumnWidth: CGFloat = 60
        let payColumnWidth: CGFloat = 70
        
        // Draw table header background
        let headerRect = CGRect(x: margin, y: currentY, width: pageRect.width - 2*margin, height: 25)
        cgContext.setFillColor(UIColor.systemGray5.cgColor)
        cgContext.fill(headerRect)
        
        currentY += 5
        
        "Data".draw(at: CGPoint(x: margin + 5, y: currentY), withAttributes: headerAttributes)
        "Horários de Trabalho".draw(at: CGPoint(x: margin + dateColumnWidth + 5, y: currentY), withAttributes: headerAttributes)
        "Horas".draw(at: CGPoint(x: margin + dateColumnWidth + timeColumnWidth + 5, y: currentY), withAttributes: headerAttributes)
        "Valor".draw(at: CGPoint(x: margin + dateColumnWidth + timeColumnWidth + hoursColumnWidth + 5, y: currentY), withAttributes: headerAttributes)
        
        currentY += 25
        
        return currentY
    }
    
    private static func drawEntries(cgContext: CGContext, entries: [WorkEntry], startIndex: Int, hourlyRate: Double, pageRect: CGRect, yPosition: inout CGFloat, tableStartY: CGFloat) -> Int {
        let margin: CGFloat = 50
        let dateColumnWidth: CGFloat = 80
        let timeColumnWidth: CGFloat = 280
        let hoursColumnWidth: CGFloat = 60
        
        let regularAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        
        var entriesDrawn = 0
        let maxYPosition = pageRect.height - 150 // Leave space for footer
        
        for index in startIndex..<entries.count {
            let entry = entries[index]
            let rowHeight = calculateRowHeight(for: entry)
            
            // Check if this entry fits on the current page
            if yPosition + rowHeight > maxYPosition && entriesDrawn > 0 {
                break // Start new page
            }
            
            // Alternate row background
            if (index - startIndex) % 2 == 0 {
                let rowRect = CGRect(x: margin, y: yPosition, width: pageRect.width - 2*margin, height: rowHeight)
                cgContext.setFillColor(UIColor.systemGray6.cgColor)
                cgContext.fill(rowRect)
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "pt_PT")
            dateFormatter.dateFormat = "d MMM"
            
            // Date - centered vertically in the row
            let dateText = dateFormatter.string(from: entry.day)
            let dateY = yPosition + (rowHeight - 12) / 2
            dateText.draw(at: CGPoint(x: margin + 5, y: dateY), withAttributes: regularAttributes)
            
            // Time periods - show all periods, each on a separate line
            var periodY = yPosition + 5
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            
            for (periodIndex, period) in entry.periods.enumerated() {
                let startTime = timeFormatter.string(from: period.startTime)
                let endTime = timeFormatter.string(from: period.endTime)
                let periodText = "Horário \(periodIndex + 1): \(startTime) - \(endTime)"
                
                // Use smaller font for individual periods if there are many
                let periodAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: entry.periods.count > 3 ? 10 : 11),
                    .foregroundColor: UIColor.black
                ]
                
                periodText.draw(at: CGPoint(x: margin + dateColumnWidth + 5, y: periodY), withAttributes: periodAttributes)
                periodY += (entry.periods.count > 3 ? 12 : 14)
            }
            
            // Hours - centered vertically in the row
            let hoursText = String(format: "%.1f", entry.workedHours)
            let hoursY = yPosition + (rowHeight - 12) / 2
            hoursText.draw(at: CGPoint(x: margin + dateColumnWidth + timeColumnWidth + 5, y: hoursY), withAttributes: regularAttributes)
            
            // Pay - centered vertically in the row
            let payText = String(format: "€%.2f", entry.calculatedPay(hourlyRate: hourlyRate))
            let payY = yPosition + (rowHeight - 12) / 2
            
            // Color code the pay based on whether it's paid or not
            let payColor = entry.isPaid ? UIColor.green : UIColor.red
            let payAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: payColor
            ]
            payText.draw(at: CGPoint(x: margin + dateColumnWidth + timeColumnWidth + hoursColumnWidth + 5, y: payY), withAttributes: payAttributes)
            
            yPosition += rowHeight
            entriesDrawn += 1
        }
        
        return entriesDrawn
    }
    
    private static func drawTableBorders(cgContext: CGContext, pageRect: CGRect, tableStartY: CGFloat, yPosition: CGFloat) {
        let margin: CGFloat = 50
        let dateColumnWidth: CGFloat = 80
        let timeColumnWidth: CGFloat = 280
        let hoursColumnWidth: CGFloat = 60
        
        // Draw table border
        let tableRect = CGRect(x: margin, y: tableStartY, width: pageRect.width - 2*margin, height: yPosition - tableStartY)
        cgContext.setStrokeColor(UIColor.black.cgColor)
        cgContext.setLineWidth(1)
        cgContext.stroke(tableRect)
        
        // Draw vertical lines for columns
        let columnXPositions: [CGFloat] = [
            margin + dateColumnWidth,
            margin + dateColumnWidth + timeColumnWidth,
            margin + dateColumnWidth + timeColumnWidth + hoursColumnWidth
        ]
        
        for xPos in columnXPositions {
            cgContext.move(to: CGPoint(x: xPos, y: tableStartY))
            cgContext.addLine(to: CGPoint(x: xPos, y: yPosition))
            cgContext.strokePath()
        }
    }
    
    private static func drawNotes(cgContext: CGContext, workMonth: WorkMonth, pageRect: CGRect, yPosition: inout CGFloat) {
        let margin: CGFloat = 50
        
        // Notes section (only if there's space and notes exist)
        if !workMonth.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && yPosition < pageRect.height - 150 {
            yPosition += 30
            
            let summaryAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.black
            ]
            
            "Notas:".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: summaryAttributes)
            yPosition += 20
            
            let notesRect = CGRect(x: margin, y: yPosition, width: pageRect.width - 2*margin, height: 80)
            cgContext.setStrokeColor(UIColor.lightGray.cgColor)
            cgContext.stroke(notesRect)
            
            let notesText = workMonth.notes
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 2
            
            let notesAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]
            
            notesText.draw(in: CGRect(x: margin + 5, y: yPosition + 5, width: pageRect.width - 2*margin - 10, height: 70),
                          withAttributes: notesAttributes)
        }
    }
    
    private static func drawFooter(cgContext: CGContext, pageRect: CGRect) {
        let margin: CGFloat = 50
        
        // Footer
        let footerY = pageRect.height - 30
        let footerText = "Gerado em \(Date().formatted(date: .abbreviated, time: .shortened))"
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),
            .foregroundColor: UIColor.gray
        ]
        footerText.draw(at: CGPoint(x: margin, y: footerY), withAttributes: footerAttributes)
    }

    // Helper function to calculate row height based on number of time periods
    private static func calculateRowHeight(for entry: WorkEntry) -> CGFloat {
        let periodsCount = entry.periods.count
        let baseHeight: CGFloat = 20
        
        if periodsCount <= 1 {
            return baseHeight
        } else if periodsCount <= 3 {
            return baseHeight + CGFloat(periodsCount - 1) * 14
        } else {
            return baseHeight + CGFloat(periodsCount - 1) * 12 // Smaller spacing for many periods
        }
    }
}

struct PDFPreviewView: View {
    let pdfData: Data
    let workMonth: WorkMonth
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            PDFKitView(data: pdfData)
                .navigationTitle("Pré-visualização")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Fechar") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: sharePDF) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
        }
    }
    
    private func sharePDF() {
        let cleanFileName = workMonth.name
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
        
        let fileName = "\(cleanFileName).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try pdfData.write(to: tempURL)
            
            let activityVC = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )
            
            activityVC.setValue(fileName, forKey: "subject")
            
            // Exclude potentially problematic activities
            activityVC.excludedActivityTypes = [
                .assignToContact,
                .addToReadingList
            ]
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                
                var topVC = rootVC
                while let presentedVC = topVC.presentedViewController {
                    topVC = presentedVC
                }
                
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = topVC.view
                    popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: 100, width: 0, height: 0)
                    popover.permittedArrowDirections = [.up]
                }
                
                topVC.present(activityVC, animated: true)
            }
            
            // Clean up after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                try? FileManager.default.removeItem(at: tempURL)
            }
            
        } catch {
            print("Failed to share PDF: \(error)")
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let data: Data
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(data: data)
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // No updates needed
    }
}

// MARK: - Updated MonthView with PDF Export
// Add this to your existing MonthView

extension MonthView {
    private var exportButton: some View {
        Button(action: exportToPDF) {
            HStack {
                Image(systemName: "doc.text")
                Text("Exportar PDF")
            }
        }
    }
    
    private func exportToPDF() {
        guard let pdfData = PDFGenerator.generatePDF(for: workMonth, hourlyRate: settings.hourlyRate) else {
            return
        }
        
        // For iOS - present share sheet
        let activityVC = UIActivityViewController(activityItems: [pdfData], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}
