import Foundation

struct WorkPeriod: Identifiable, Codable, Equatable {
    let id = UUID()
    var startTime: Date
    var endTime: Date
    
    var workedHours: Double {
        guard endTime > startTime else { return 0 }
        return endTime.timeIntervalSince(startTime) / 3600
    }
    
    var isValid: Bool {
        return endTime > startTime
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: startTime))-\(formatter.string(from: endTime))"
    }
}

struct WorkEntry: Identifiable, Codable, Equatable {
    let id = UUID()
    var day: Date
    var periods: [WorkPeriod]
    
    var workedHours: Double {
        return periods.reduce(0) { $0 + $1.workedHours }
    }

    func calculatedPay(hourlyRate: Double) -> Double {
        return workedHours * hourlyRate
    }
    
    var isValid: Bool {
        return !periods.isEmpty && periods.allSatisfy { $0.isValid }
    }
    
    var isEmpty: Bool {
        return periods.isEmpty
    }
    
    // Helper to get formatted time periods string
    var timePeriodsString: String {
        return periods.map { $0.timeString }.joined(separator: " | ")
    }
    
    // Initialize with default periods for convenience
    init(day: Date, periods: [WorkPeriod] = []) {
        self.day = day
        self.periods = periods.isEmpty ? [WorkPeriod.defaultPeriod(for: day)] : periods
    }
}

extension WorkPeriod {
    static func defaultPeriod(for date: Date) -> WorkPeriod {
        let weekday = Calendar.current.component(.weekday, from: date)
        let (startHour, startMinute, endHour, endMinute): (Int, Int, Int, Int)
        
        switch weekday {
        case 2, 4, 6: // Monday, Wednesday, Friday
            (startHour, startMinute, endHour, endMinute) = (17, 0, 20, 0)
        case 1: // Sunday
            (startHour, startMinute, endHour, endMinute) = (0, 0, 0, 0)
        default: // Tuesday, Thursday, Saturday
            (startHour, startMinute, endHour, endMinute) = (8, 0, 12, 0)
        }
        
        let startTime = Calendar.current.date(bySettingHour: startHour, minute: startMinute, second: 0, of: date) ?? date
        let endTime = Calendar.current.date(bySettingHour: endHour, minute: endMinute, second: 0, of: date) ?? date
        
        return WorkPeriod(startTime: startTime, endTime: endTime)
    }
}

struct WorkMonth: Identifiable, Codable, Equatable {
    let id = UUID()
    var month: Date
    var entries: [WorkEntry]
    var notes: String
    var name: String

    func totalPay(hourlyRate: Double) -> Double {
        return entries.reduce(0) { $0 + $1.calculatedPay(hourlyRate: hourlyRate) }
    }
    
    var totalHours: Double {
        return entries.reduce(0) { $0 + $1.workedHours }
    }

    var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_PT")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: month)
    }
    
    // Helper to get entries sorted by date
    var sortedEntries: [WorkEntry] {
        return entries.sorted { $0.day < $1.day }
    }
    
    // Helper to check if month has content
    var hasContent: Bool {
        return !entries.isEmpty || !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
