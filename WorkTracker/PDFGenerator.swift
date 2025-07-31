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
            context.beginPage()
            
            let cgContext = context.cgContext
            drawPDFContent(cgContext: cgContext, workMonth: workMonth, hourlyRate: hourlyRate, pageRect: pageRect)
        }
        
        return data
    }
    
    private static func drawPDFContent(cgContext: CGContext, workMonth: WorkMonth, hourlyRate: Double, pageRect: CGRect) {
        let margin: CGFloat = 50
        var yPosition: CGFloat = margin
        
        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.black
        ]
        
        let title = workMonth.name
        title.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttributes)
        yPosition += 40
        
        // Month info
        let monthAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.gray
        ]
        
        workMonth.monthName.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: monthAttributes)
        yPosition += 30
        
        // Summary section
        let summaryAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor.black
        ]
        
        let regularAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        
        // Draw summary box
        let summaryRect = CGRect(x: margin, y: yPosition, width: pageRect.width - 2*margin, height: 80)
        cgContext.setStrokeColor(UIColor.lightGray.cgColor)
        cgContext.setLineWidth(1)
        cgContext.stroke(summaryRect)
        
        yPosition += 15
        
        // Summary content
        "Resumo".draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: summaryAttributes)
        yPosition += 20
        
        let totalHours = String(format: "Total de Horas: %.1f", workMonth.totalHours)
        totalHours.draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: regularAttributes)
        
        let paidHours = String(format: "Horas Pagas: %.1f", workMonth.totalPaidHours)
        paidHours.draw(at: CGPoint(x: margin + 200, y: yPosition), withAttributes: regularAttributes)
        yPosition += 15
        
        let hourlyRateText = String(format: "Taxa Horária: €%.2f", hourlyRate)
        hourlyRateText.draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: regularAttributes)
        
        let totalPay = String(format: "Total Pago: €%.2f", workMonth.totalActualPay(hourlyRate: hourlyRate))
        totalPay.draw(at: CGPoint(x: margin + 200, y: yPosition), withAttributes: regularAttributes)
        yPosition += 40
        
        // Table header
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        
        // Draw table header background
        let headerRect = CGRect(x: margin, y: yPosition, width: pageRect.width - 2*margin, height: 25)
        cgContext.setFillColor(UIColor.systemGray5.cgColor)
        cgContext.fill(headerRect)
        
        yPosition += 5
        
        "Data".draw(at: CGPoint(x: margin + 5, y: yPosition), withAttributes: headerAttributes)
        "Horários".draw(at: CGPoint(x: margin + 100, y: yPosition), withAttributes: headerAttributes)
        "Horas".draw(at: CGPoint(x: margin + 300, y: yPosition), withAttributes: headerAttributes)
        "Valor".draw(at: CGPoint(x: margin + 360, y: yPosition), withAttributes: headerAttributes)
        "Feito".draw(at: CGPoint(x: margin + 420, y: yPosition), withAttributes: headerAttributes)
        
        yPosition += 25
        
        // Draw table border
        let tableStartY = yPosition - 25
        cgContext.setStrokeColor(UIColor.black.cgColor)
        cgContext.setLineWidth(1)
        
        // Entries
        let sortedEntries = workMonth.sortedEntries
        for (index, entry) in sortedEntries.enumerated() {
            // Alternate row background
            if index % 2 == 0 {
                let rowRect = CGRect(x: margin, y: yPosition, width: pageRect.width - 2*margin, height: 20)
                cgContext.setFillColor(UIColor.systemGray6.cgColor)
                cgContext.fill(rowRect)
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "pt_PT")
            dateFormatter.dateFormat = "d MMM"
            
            // Date
            let dateText = dateFormatter.string(from: entry.day)
            dateText.draw(at: CGPoint(x: margin + 5, y: yPosition + 2), withAttributes: regularAttributes)
            
            // Time periods
            let timePeriodsText = entry.timePeriodsString
            let truncatedTime = timePeriodsText.count > 25 ? String(timePeriodsText.prefix(25)) + "..." : timePeriodsText
            truncatedTime.draw(at: CGPoint(x: margin + 100, y: yPosition + 2), withAttributes: regularAttributes)
            
            // Hours
            let hoursText = String(format: "%.1f", entry.workedHours)
            hoursText.draw(at: CGPoint(x: margin + 300, y: yPosition + 2), withAttributes: regularAttributes)
            
            // Pay
            let payText = String(format: "€%.2f", entry.calculatedPay(hourlyRate: hourlyRate))
            payText.draw(at: CGPoint(x: margin + 360, y: yPosition + 2), withAttributes: regularAttributes)
            
            // Paid status
            let paidText = entry.isPaid ? "✓" : "✗"
            let paidColor = entry.isPaid ? UIColor.green : UIColor.red
            let paidAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 12),
                .foregroundColor: paidColor
            ]
            paidText.draw(at: CGPoint(x: margin + 430, y: yPosition + 2), withAttributes: paidAttributes)
            
            yPosition += 20
            
            // Check if we need a new page
            if yPosition > pageRect.height - 100 {
                // Start new page if needed
                break
            }
        }
        
        // Draw table border
        let tableRect = CGRect(x: margin, y: tableStartY, width: pageRect.width - 2*margin, height: yPosition - tableStartY)
        cgContext.stroke(tableRect)
        
        // Draw vertical lines for columns
        let columnXPositions: [CGFloat] = [margin + 95, margin + 295, margin + 355, margin + 415]
        for xPos in columnXPositions {
            cgContext.move(to: CGPoint(x: xPos, y: tableStartY))
            cgContext.addLine(to: CGPoint(x: xPos, y: yPosition))
            cgContext.strokePath()
        }
        
        // Notes section
        if !workMonth.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            yPosition += 30
            
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
        
        // Footer
        let footerY = pageRect.height - 30
        let footerText = "Gerado em \(Date().formatted(date: .abbreviated, time: .shortened))"
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),
            .foregroundColor: UIColor.gray
        ]
        footerText.draw(at: CGPoint(x: margin, y: footerY), withAttributes: footerAttributes)
    }
}

// MARK: - PDF Preview View
/*struct PDFPreviewView: View {
    let pdfData: Data
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
                        ShareLink(item: pdfData, preview: SharePreview("Folha de Trabalho", image: Image(systemName: "doc.text"))) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
        }
    }
}*/

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
