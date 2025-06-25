import SwiftUI

struct MonthView: View {
    @Binding var workMonth: WorkMonth
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        VStack {
            List {
                ForEach($workMonth.entries) { $entry in
                    HStack {
                        DatePicker("", selection: $entry.day, displayedComponents: .date)
                            .labelsHidden()

                        VStack(alignment: .leading) {
                            DatePicker("Início", selection: $entry.startTime, displayedComponents: [.hourAndMinute])
                                .labelsHidden()

                            DatePicker("Fim", selection: $entry.endTime, displayedComponents: [.hourAndMinute])
                                .labelsHidden()
                        }

                        Spacer()

                        Text(String(format: "%.1f €", entry.calculatedPay(hourlyRate: settings.hourlyRate)))
                            .frame(minWidth: 80, alignment: .trailing)
                    }
                }
            }

            // Notas
            TextEditor(text: $workMonth.notes)
                .frame(height: 100)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))

            // Adicionar nova entrada
            if !isLastDayOfMonth() {
                Button("Adicionar dia") {
                    let nextDate: Date
                    
                    if let lastDay = workMonth.entries.sorted(by: { $0.day < $1.day }).last?.day {

                        nextDate = Calendar.current.date(byAdding: .day, value: 1, to: lastDay) ?? workMonth.month
                    } else {
                        let calendar = Calendar.current
                        let year = calendar.component(.year, from: workMonth.month)
                        let month = calendar.component(.month, from: workMonth.month)
                        
                        var components = DateComponents()
                        components.year = year
                        components.month = month
                        components.day = 1
                        
                        nextDate = calendar.date(from: components) ?? workMonth.month
                    }
                    
                    let weekday = Calendar.current.component(.weekday, from: nextDate)
                    let (startHour, startMinute, endHour, endMinute): (Int, Int, Int, Int)
                    
                    if weekday == 2 || weekday == 4 || weekday == 6 {
                        (startHour, startMinute, endHour, endMinute) = (17, 0, 20, 0)
                    } else
                    if weekday == 1 {
                        (startHour, startMinute, endHour, endMinute) = (0, 0, 0, 0)
                    }else {
                        (startHour, startMinute, endHour, endMinute) = (8, 0, 12, 0)
                    }

                    let startTime = Calendar.current.date(bySettingHour: startHour, minute: startMinute, second: 0, of: nextDate)!
                    let endTime = Calendar.current.date(bySettingHour: endHour, minute: endMinute, second: 0, of: nextDate)!

                    workMonth.entries.append(WorkEntry(day: nextDate, startTime: startTime, endTime: endTime))
                }
                .padding()
            }

            // Total
            Text("Total: \(String(format: "%.2f €", workMonth.entries.reduce(0) { $0 + $1.calculatedPay(hourlyRate: settings.hourlyRate) }))")
                .font(.title2)
                .bold()
                .padding(.bottom)
        }
    }
    
    private func isLastDayOfMonth() -> Bool {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: workMonth.month)
        let month = calendar.component(.month, from: workMonth.month)
        
        let range = calendar.range(of: .day, in: .month, for: workMonth.month)
        let lastDayOfMonth = range?.upperBound ?? 1
        
        return workMonth.entries.contains { entry in
            let entryYear = calendar.component(.year, from: entry.day)
            let entryMonth = calendar.component(.month, from: entry.day)
            let entryDay = calendar.component(.day, from: entry.day)
            
            return entryYear == year && entryMonth == month && entryDay == (lastDayOfMonth - 1)
        }
    }
}
