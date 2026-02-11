import Foundation
import WidgetKit

class SharedDataManager {
    static let shared = SharedDataManager()
    
    // The App Group ID must match the one in Entitlements
    let appGroupId = "group.com.mindfulnessapp.shared"
    
    // Keys
    private let keyTodayMindfulnessMinutes = "todayMindfulnessMinutes"
    
    private var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupId)
    }
    
    private init() {}
    
    func saveTodayMindfulnessMinutes(_ minutes: Double) {
        sharedDefaults?.set(minutes, forKey: keyTodayMindfulnessMinutes)
        // Reload widget timeline specific to our kind
        WidgetCenter.shared.reloadTimelines(ofKind: "MindfulnessWidget")
    }
    
    func getTodayMindfulnessMinutes() -> Double {
        return sharedDefaults?.double(forKey: keyTodayMindfulnessMinutes) ?? 0.0
    }
}
