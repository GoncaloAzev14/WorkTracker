import SwiftUI

struct MonthView: View {
    @Binding var workMonth: WorkMonth

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

                        Text(String(format: "%.1f €", entry.calculatedPay))
                            .frame(minWidth: 80, alignment: .trailing)
                    }
                }
            }

            // Notas
            TextEditor(text: $workMonth.notes)
                .frame(height: 100)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))

            // Adicionar nova entrada
            Button("Adicionar dia") {
                let nextDate: Date
                if let lastDay = workMonth.entries.sorted(by: { $0.day < $1.day }).last?.day {
                    nextDate = Calendar.current.date(byAdding: .day, value: 1, to: lastDay) ?? Date()
                } else {
                    nextDate = Date()
                }
                
                let weekday = Calendar.current.component(.weekday, from: nextDate)
                let (startHour, startMinute, endHour, endMinute): (Int, Int, Int, Int)
                
                if weekday == 2 || weekday == 4 || weekday == 6 {
                    (startHour, startMinute, endHour, endMinute) = (17, 0, 20, 0)
                }else{
                    (startHour, startMinute, endHour, endMinute) = (8, 0, 12, 0)
                }

                let startTime = Calendar.current.date(bySettingHour: startHour, minute: startMinute, second: 0, of: nextDate)!
                let endTime = Calendar.current.date(bySettingHour: endHour, minute: endMinute, second: 0, of: nextDate)!

                workMonth.entries.append(WorkEntry(day: nextDate, startTime: startTime, endTime: endTime))
            }
            .padding()

            // Total
            Text("Total: \(String(format: "%.2f €", workMonth.totalPay))")
                .font(.title2)
                .bold()
                .padding(.bottom)
        }
    }
}
