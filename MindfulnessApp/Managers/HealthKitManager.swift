import Foundation
import HealthKit
import Combine

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    
    private init() {}
    
    // Request Authorization
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(domain: "com.mindfulnessapp", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device."]))
            return
        }
        
        guard let mindfulnessType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            completion(false, NSError(domain: "com.mindfulnessapp", code: 2, userInfo: [NSLocalizedDescriptionKey: "Mindfulness Session type is unavailable."]))
            return
        }
        
        let typesToShare: Set = [mindfulnessType, HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!]
        let typesToRead: Set = [mindfulnessType, HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                self.isAuthorized = success
                completion(success, error)
            }
        }
    }
    
    // Save Mindfulness Session
    func saveMindfulnessSession(startTime: Date, endTime: Date, completion: @escaping (Bool, Error?) -> Void) {
        guard let mindfulnessType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            completion(false, NSError(domain: "com.mindfulnessapp", code: 3, userInfo: [NSLocalizedDescriptionKey: "无法获取正念类型"]))
            return
        }
        
        let mindfulSession = HKCategorySample(type: mindfulnessType, value: 0, start: startTime, end: endTime)
        
        healthStore.save(mindfulSession) { success, error in
            completion(success, error)
        }
    }

    // Save Sleep Analysis
    func saveSleepAnalysis(startTime: Date, endTime: Date, completion: @escaping (Bool, Error?) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(false, NSError(domain: "com.mindfulnessapp", code: 4, userInfo: [NSLocalizedDescriptionKey: "无法获取睡眠类型"]))
            return
        }
        
        // For simplicity, we save as "InBed" or "Asleep". Since user just records "Sleep", "Asleep" (Unspecified) is appropriate or InBed.
        // Let's use .asleepUnspecified for general sleep recording if available, or .inBed.
        // Actually, for manual entry, .asleep is best.
        let sleepSample = HKCategorySample(type: sleepType, value: HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue, start: startTime, end: endTime)
        
        healthStore.save(sleepSample) { success, error in
            completion(success, error)
        }
    }
    
    // Fetch Recent Sessions (Mindfulness & Sleep)
    func fetchRecentSessions(limit: Int = 20, completion: @escaping ([MindfulnessSession]?, Error?) -> Void) {
        let mindfulnessType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        
        // Filter by current app source
        let sourcePredicate = HKQuery.predicateForObjects(from: .default())
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        // Run two queries in parallel (simplified)
        var allSessions: [MindfulnessSession] = []
        let group = DispatchGroup()
        
        // 1. Mindfulness
        group.enter()
        let q1 = HKSampleQuery(sampleType: mindfulnessType, predicate: sourcePredicate, limit: limit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            if let samples = samples as? [HKCategorySample] {
                let s = samples.map { MindfulnessSession(startDate: $0.startDate, endDate: $0.endDate, type: .mindfulness) }
                allSessions.append(contentsOf: s)
            }
            group.leave()
        }
        healthStore.execute(q1)
        
        // 2. Sleep
        group.enter()
        let q2 = HKSampleQuery(sampleType: sleepType, predicate: sourcePredicate, limit: limit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            if let samples = samples as? [HKCategorySample] {
                // Sleep samples might be fragmented (InBed, AsleepUnspecified).
                // We just map valid samples.
                // Filter out short samples if needed? Or just show raw records.
                // Assuming "Asleep" or "InBed" records created by US are valid sessions.
                let s = samples.map { MindfulnessSession(startDate: $0.startDate, endDate: $0.endDate, type: .sleep) }
                allSessions.append(contentsOf: s)
            }
            group.leave()
        }
        healthStore.execute(q2)
        
        group.notify(queue: .main) {
            // Sort combined list
            let sorted = allSessions.sorted { $0.endDate > $1.endDate }
            completion(Array(sorted.prefix(limit)), nil)
        }
    }
    
    // Fetch Today's Total Minutes
    func fetchTodayTotalMinutes(completion: @escaping (Double) -> Void) {
        guard let mindfulnessType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: mindfulnessType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            
            guard let samples = samples as? [HKCategorySample], error == nil else {
                completion(0.0)
                return
            }
            
            let totalSeconds = samples.reduce(0.0) { result, sample in
                return result + sample.endDate.timeIntervalSince(sample.startDate)
            }
            
            let totalMinutes = totalSeconds / 60.0
            
            // Sync to Shared Data for Widget
            SharedDataManager.shared.saveTodayMindfulnessMinutes(totalMinutes)
            
            completion(totalMinutes)
        }
        
        healthStore.execute(query)
    }
    
    // Fetch This Week's Data for Charts
    func fetchThisWeekSessions(completion: @escaping ([MindfulnessSession]) -> Void) {
         guard let mindfulnessType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else { return }
         
         let calendar = Calendar.current
         let today = Date()
         // Get the start of the week (e.g. Sunday or Monday depending on locale)
         guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
             completion([])
             return
         }
         
         let predicate = HKQuery.predicateForSamples(withStart: startOfWeek, end: today, options: [])
         
        let query = HKSampleQuery(sampleType: mindfulnessType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { _, samples, error in
             guard let samples = samples as? [HKCategorySample], error == nil else {
                 completion([])
                 return
             }
             
             let sessions = samples.map { sample in
                 MindfulnessSession(startDate: sample.startDate, endDate: sample.endDate, type: .mindfulness)
             }
             completion(sessions)
         }
         healthStore.execute(query)
    }
    // Fetch Sessions in Range
    func fetchSessions(start: Date, end: Date, completion: @escaping ([MindfulnessSession]) -> Void) {
        guard let mindfulnessType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false) // Newest first
        
        let query = HKSampleQuery(sampleType: mindfulnessType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard let samples = samples as? [HKCategorySample], error == nil else {
                completion([])
                return
            }
            
            let sessions = samples.map { sample in
                MindfulnessSession(startDate: sample.startDate, endDate: sample.endDate, type: .mindfulness)
            }
            completion(sessions)
        }
        healthStore.execute(query)
    }
}
