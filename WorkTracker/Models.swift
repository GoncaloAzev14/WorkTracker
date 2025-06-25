import Foundation

struct WorkEntry: Identifiable, Codable {
    let id = UUID()
    var day: Date
    var startTime: Date
    var endTime: Date
    
    var workedHours: Double {
        return endTime.timeIntervalSince(startTime) / 3600
    }

    func calculatedPay(hourlyRate: Double) -> Double {
            workedHours * hourlyRate
    }
}


struct WorkMonth: Identifiable, Codable {
    let id = UUID()
    var month: Date
    var entries: [WorkEntry]
    var notes: String
    var name: String

    func totalPay(hourlyRate: Double) -> Double {
        entries.reduce(0) { $0 + $1.calculatedPay(hourlyRate: hourlyRate) }
    }

    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: month)
    }
}
