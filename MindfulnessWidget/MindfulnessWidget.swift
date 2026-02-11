import WidgetKit
import SwiftUI


struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), totalMinutes: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), totalMinutes: 15) // Preview Data
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Read from shared UserDefaults instead of querying HealthKit directly
        // This ensures data is available even if the device is locked/HealthKit is inaccessible
        let appGroupId = "group.com.mindfulnessapp.shared"
        let keyTodayMindfulnessMinutes = "todayMindfulnessMinutes"
        
        let sharedDefaults = UserDefaults(suiteName: appGroupId)
        let totalMinutes = sharedDefaults?.double(forKey: keyTodayMindfulnessMinutes) ?? 0.0
        
        let currentDate = Date()
        let entry = SimpleEntry(date: currentDate, totalMinutes: totalMinutes)
        
        // Update policies
        // .never means we rely on the app to reload the timeline when data changes
        // but adding a backup refresh capability is fine.
        let nextUpdate = currentDate.addingTimeInterval(30 * 60) // Backup update every 30 mins
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
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
