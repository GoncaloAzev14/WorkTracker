import Foundation

struct WorkEntry: Identifiable, Codable {
    let id = UUID()
    var day: Date
    var startTime: Date
    var endTime: Date
    
    var workedHours: Double {
        return endTime.timeIntervalSince(startTime) / 3600
    }

    var calculatedPay: Double {
        return workedHours * 5.0
    }
}


struct WorkMonth: Identifiable, Codable {
    let id = UUID()
    var month: Date
    var entries: [WorkEntry]
    var notes: String
    var name: String

    var totalPay: Double {
        entries.reduce(0) { $0 + $1.calculatedPay }
    }

    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: month)
    }
}
