import Foundation
import Combine
import WidgetKit
import SwiftUI

class MindfulnessViewModel: ObservableObject {
    @Published var totalMinutesToday: Double = 0.0
    @Published var recentSessions: [MindfulnessSession] = []
    @Published var weeklySessions: [MindfulnessSession] = []
    @Published var isRecording: Bool = false
    @Published var currentSessionStartTime: Date?
    @Published var elapsedTime: TimeInterval = 0
    @Published var weeklyData: [DailyData] = []
    
    @Published var dailyGoal: Double = UserDefaults.standard.double(forKey: "dailyGoal") == 0 ? 30.0 : UserDefaults.standard.double(forKey: "dailyGoal") {
        didSet {
            UserDefaults.standard.set(dailyGoal, forKey: "dailyGoal")
        }
    }
    
    @Published var showSleepRecording: Bool = UserDefaults.standard.bool(forKey: "showSleepRecording") {
        didSet {
            UserDefaults.standard.set(showSleepRecording, forKey: "showSleepRecording")
        }
    }
    @Published var historyData: [Date: Double] = [:] // Start of day -> Total Minutes
    
    // Sleep Record Toast State
    @Published var showSleepToast: Bool = false
    @Published var sleepToastMessage: String = ""
    private var pendingSleepSaveItem: DispatchWorkItem?
    
    private var healthKitManager = HealthKitManager.shared
    private var timer: Timer?
    
    init() {
        requestAuthorization()
    }
    
    func requestAuthorization() {
        healthKitManager.requestAuthorization { success, error in
            if success {
                self.fetchData()
                self.fetchHistoryData()
            }
        }
    }
    
    func fetchData() {
        healthKitManager.fetchTodayTotalMinutes { minutes in
            DispatchQueue.main.async {
                self.totalMinutesToday = minutes
            }
        }
        
        healthKitManager.fetchRecentSessions { sessions, _ in
            if let sessions = sessions {
                DispatchQueue.main.async {
                    self.recentSessions = sessions
                }
            }
        }
        
        healthKitManager.fetchThisWeekSessions { sessions in
            DispatchQueue.main.async {
                self.weeklySessions = sessions
                self.processWeeklyData(sessions)
            }
        }
    }
    
    func fetchHistoryData() {
        // Fetch last 365 days
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .year, value: -1, to: endDate) else { return }
        
        // Use HKSampleQuery (via HealthKitManager) to get all samples in range
        // Since we don't have a direct "fetchAll" in HKManager yet, let's add or reuse.
        // Actually `fetchMindfulnessSessions` fetches recent (limit 100).
        // `fetchThisWeekSessions` fetches week.
        // We probably need a generic fetch in HKManager or here. 
        // For simplicity, let's assume we add a helper or extend fetched sessions.
        // Let's implement a specific fetch in ViewModel relying on a new hypothetical HK method or existing.
        // Wait, I should add the method to HKManager first or use what I have.
        // Let's check HKManager.
        
        // For now, let's assume we add a method to HealthKitManager or use a direct query.
        // I'll add `fetchHistorySessions` logic here for now calling a new manager method.
        healthKitManager.fetchSessions(start: startDate, end: endDate) { sessions in
            DispatchQueue.main.async {
                self.processHistoryData(sessions)
            }
        }
    }
    
    private func processHistoryData(_ sessions: [MindfulnessSession]) {
        var counts: [Date: Double] = [:]
        let calendar = Calendar.current
        
        for session in sessions {
            let startOfDay = calendar.startOfDay(for: session.startDate)
            counts[startOfDay, default: 0] += session.durationInMinutes
        }
        
        self.historyData = counts
    }
    
    func updateDailyGoal(_ minutes: Double) {
        dailyGoal = minutes
        UserDefaults.standard.set(minutes, forKey: "dailyGoal")
    }
    
    private func processWeeklyData(_ sessions: [MindfulnessSession]) {
        let calendar = Calendar.current
        let today = Date()
        
        // Initialize last 7 days
        var days: [Date] = []
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                days.append(date)
            }
        }
        days.reverse() // Chronological order
        
        var finalData: [DailyData] = []
        
        for date in days {
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let sessionsForDay = sessions.filter { $0.startDate >= startOfDay && $0.startDate < endOfDay }
            let totalMinutes = sessionsForDay.reduce(0) { $0 + $1.durationInMinutes }
            
            finalData.append(DailyData(date: date, weekday: getWeekday(date: date), minutes: totalMinutes))
        }
        
        self.weeklyData = finalData
        
        // Save to Shared UserDefaults for Widget
        if let sharedDefaults = UserDefaults(suiteName: "group.com.mindfulnessapp.shared") {
            if let encoded = try? JSONEncoder().encode(finalData) {
                sharedDefaults.set(encoded, forKey: "weeklyMindfulnessData")
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
    
    private func getWeekday(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEE" // 周一, 周二...
        return formatter.string(from: date)
    }
    
    // MARK: - Session Recording
    
    func startSession() {
        isRecording = true
        currentSessionStartTime = Date()
        elapsedTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.elapsedTime += 1
        }
    }
    
    func endSession() {
        guard let startTime = currentSessionStartTime else { return }
        isRecording = false
        timer?.invalidate()
        timer = nil
        let endTime = Date()
        
        healthKitManager.saveMindfulnessSession(startTime: startTime, endTime: endTime) { success, _ in
            if success {
                self.fetchData()
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
        currentSessionStartTime = nil
    }
    
    func addManualSession(minutes: Double, completion: @escaping (Bool) -> Void = { _ in }) {
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-minutes * 60)
        
        healthKitManager.saveMindfulnessSession(startTime: startDate, endTime: endDate) { success, _ in
            if success {
                self.fetchData()
                WidgetCenter.shared.reloadAllTimelines()
            }
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    /// 在指定时间添加正念记录
    /// - Parameters:
    ///   - minutes: 正念时长（分钟）
    ///   - date: 开始时间
    func addManualSession(minutes: Double, at date: Date, completion: @escaping (Bool) -> Void = { _ in }) {
        let startDate = date
        let endDate = date.addingTimeInterval(minutes * 60)
        
        healthKitManager.saveMindfulnessSession(startTime: startDate, endTime: endDate) { success, _ in
            if success {
                self.fetchData()
                self.fetchHistoryData()
                WidgetCenter.shared.reloadAllTimelines()
            }
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }

    func saveSpecificSession(start: Date, end: Date, completion: @escaping (Bool) -> Void = { _ in }) {
        healthKitManager.saveMindfulnessSession(startTime: start, endTime: end) { success, _ in
            if success {
                self.fetchData()
                self.fetchHistoryData() // Don't forget history!
                WidgetCenter.shared.reloadAllTimelines()
            }
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    func saveSleepSession(start: Date, end: Date, completion: @escaping (Bool) -> Void = { _ in }) {
        healthKitManager.saveSleepAnalysis(startTime: start, endTime: end) { success, _ in
             DispatchQueue.main.async {
                 completion(success)
             }
        }
    }
    
    func preSaveSleep(start: Date, end: Date, message: String) {
        // 1. Show Toast
        sleepToastMessage = message
        withAnimation {
            showSleepToast = true
        }
        
        // 2. Schedule Save
        let item = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.saveSleepSession(start: start, end: end)
            withAnimation {
                self.showSleepToast = false
            }
        }
        pendingSleepSaveItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: item)
    }
    
    func undoSleepSave() {
        pendingSleepSaveItem?.cancel()
        pendingSleepSaveItem = nil
        withAnimation {
            showSleepToast = false
        }
    }
    
    // MARK: - Mock for Previews
    static var mock: MindfulnessViewModel {
        let vm = MindfulnessViewModel(mockData: true)
        vm.totalMinutesToday = 45
        vm.dailyGoal = 60
        vm.weeklyData = [
            DailyData(date: Date(), weekday: "周一", minutes: 30),
            DailyData(date: Date().addingTimeInterval(86400), weekday: "周二", minutes: 45),
            DailyData(date: Date().addingTimeInterval(86400*2), weekday: "周三", minutes: 60),
            DailyData(date: Date().addingTimeInterval(86400*3), weekday: "周四", minutes: 15),
            DailyData(date: Date().addingTimeInterval(86400*4), weekday: "周五", minutes: 0),
            DailyData(date: Date().addingTimeInterval(86400*5), weekday: "周六", minutes: 90),
            DailyData(date: Date().addingTimeInterval(86400*6), weekday: "周日", minutes: 30)
        ]
        
        // Mock history for last 30 days
        let calendar = Calendar.current
        let today = Date()
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let startOfDay = calendar.startOfDay(for: date)
                vm.historyData[startOfDay] = Double.random(in: 0...90)
            }
        }
        
        // Mock recent sessions
        vm.recentSessions = [
            MindfulnessSession(startDate: Date().addingTimeInterval(-3600), endDate: Date().addingTimeInterval(-1800), type: .mindfulness),
            MindfulnessSession(startDate: Date().addingTimeInterval(-86400), endDate: Date().addingTimeInterval(-86400 + 1200), type: .mindfulness),
            MindfulnessSession(startDate: Date().addingTimeInterval(-172800), endDate: Date().addingTimeInterval(-172800 + 28000), type: .sleep)
        ]
        
        return vm
    }
    
    init(mockData: Bool = false) {
        if !mockData {
            requestAuthorization()
        }
    }
}

struct DailyData: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let weekday: String
    let minutes: Double
}
