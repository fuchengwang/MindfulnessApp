import Foundation

struct MindfulnessSession: Identifiable, Hashable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    
    var duration: TimeInterval {
        return endDate.timeIntervalSince(startDate)
    }
    
    var durationInMinutes: Double {
        return duration / 60.0
    }
}
