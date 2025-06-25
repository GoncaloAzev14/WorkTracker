/*import Foundation

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
*/
//v1
/*
import Foundation

struct WorkEntry: Identifiable, Codable {
    let id = UUID()
    var day: Date
    var startTime: Date
    var endTime: Date
    
    var workedHours: Double {
        // Ensure end time is after start time
        guard endTime > startTime else { return 0 }
        return endTime.timeIntervalSince(startTime) / 3600
    }

    func calculatedPay(hourlyRate: Double) -> Double {
        return workedHours * hourlyRate
    }
    
    // Helper to check if this entry is valid
    var isValid: Bool {
        return endTime > startTime
    }
}

struct WorkMonth: Identifiable, Codable {
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
*/
import Foundation

struct WorkEntry: Identifiable, Codable, Equatable {
    let id = UUID()
    var day: Date
    var startTime: Date
    var endTime: Date
    
    var workedHours: Double {
        // Ensure end time is after start time
        guard endTime > startTime else { return 0 }
        return endTime.timeIntervalSince(startTime) / 3600
    }

    func calculatedPay(hourlyRate: Double) -> Double {
        return workedHours * hourlyRate
    }
    
    // Helper to check if this entry is valid
    var isValid: Bool {
        return endTime > startTime
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
