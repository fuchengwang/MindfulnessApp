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
        
        let typesToShare: Set = [mindfulnessType]
        let typesToRead: Set = [mindfulnessType]
        
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
    
    // Fetch Recent Sessions
    func fetchMindfulnessSessions(limit: Int = 10, completion: @escaping ([MindfulnessSession]?, Error?) -> Void) {
        guard let mindfulnessType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: mindfulnessType, predicate: nil, limit: limit, sortDescriptors: [sortDescriptor]) { _, samples, error in
            
            guard let samples = samples as? [HKCategorySample], error == nil else {
                completion(nil, error)
                return
            }
            
            let sessions = samples.map { sample in
                MindfulnessSession(startDate: sample.startDate, endDate: sample.endDate)
            }
            
            completion(sessions, nil)
        }
        
        healthStore.execute(query)
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
            
            completion(totalSeconds / 60.0)
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
                 MindfulnessSession(startDate: sample.startDate, endDate: sample.endDate)
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
                MindfulnessSession(startDate: sample.startDate, endDate: sample.endDate)
            }
            completion(sessions)
        }
        healthStore.execute(query)
    }
}
