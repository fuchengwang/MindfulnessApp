import WidgetKit
import SwiftUI
import HealthKit

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), totalMinutes: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), totalMinutes: 15) // Preview Data
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Fetch data from HealthKit
        // Note: HealthKit data might be unavailable if device is locked.
        let currentDate = Date()
        let startOfDay = Calendar.current.startOfDay(for: currentDate)
        
        let healthStore = HKHealthStore()
        guard HKHealthStore.isHealthDataAvailable(),
              let type = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            let entry = SimpleEntry(date: currentDate, totalMinutes: 0)
            let timeline = Timeline(entries: [entry], policy: .after(currentDate.addingTimeInterval(3600)))
            completion(timeline)
            return
        }
        
        // Predicate for today
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: currentDate, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            
            var totalMinutes = 0.0
            
            if let samples = samples as? [HKCategorySample] {
                let totalSeconds = samples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                totalMinutes = totalSeconds / 60.0
            }
            
            let entry = SimpleEntry(date: currentDate, totalMinutes: totalMinutes)
            let nextUpdate = currentDate.addingTimeInterval(15 * 60) // Update every 15 mins
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            
            completion(timeline)
        }
        
        healthStore.execute(query)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let totalMinutes: Double
}

struct MindfulnessWidgetEntryView : View {
    var entry: Provider.Entry
    
    // Theme colors matching the main app
    let gradientStart = Color(red: 0.2, green: 0.6, blue: 0.8)
    let gradientEnd = Color(red: 0.2, green: 0.8, blue: 0.7)

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.white)
                Text("正念")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text("\(Int(entry.totalMinutes))")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("今日分钟")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetBackground(
            LinearGradient(gradient: Gradient(colors: [gradientStart, gradientEnd]), startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }
}

extension View {
    func widgetBackground(_ backgroundView: some View) -> some View {
        if #available(iOS 17.0, *) {
            return containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            return background(backgroundView)
        }
    }
}


struct MindfulnessWidget: Widget {
    let kind: String = "MindfulnessWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MindfulnessWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("正念统计")
        .description("查看今天的正念总时长。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    MindfulnessWidget()
} timeline: {
    SimpleEntry(date: .now, totalMinutes: 15)
    SimpleEntry(date: .now, totalMinutes: 45)
}

#Preview(as: .systemMedium) {
    MindfulnessWidget()
} timeline: {
    SimpleEntry(date: .now, totalMinutes: 30)
}
