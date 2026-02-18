import Foundation

struct MindfulnessSession: Identifiable, Hashable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    
    enum SessionType: String, Codable {
        case mindfulness
        case sleep
    }
    
    let type: SessionType
    
    var duration: TimeInterval {
        return endDate.timeIntervalSince(startDate)
    }
    
    var durationInMinutes: Double {
        return duration / 60.0
    }
}
