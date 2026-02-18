import WidgetKit
import SwiftUI

// Local definition matching the main app's DailyData
struct WidgetDailyData: Identifiable, Codable {
    let id: UUID
    let date: Date
    let weekday: String
    let minutes: Double
}

struct WeeklyTrendProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeeklyEntry {
        WeeklyEntry(date: Date(), data: mockData())
    }

    func getSnapshot(in context: Context, completion: @escaping (WeeklyEntry) -> ()) {
        let entry = WeeklyEntry(date: Date(), data: mockData())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeeklyEntry>) -> ()) {
        let appGroupId = "group.com.mindfulnessapp.shared"
        let key = "weeklyMindfulnessData"
        
        var data: [WidgetDailyData] = []
        
        if let sharedDefaults = UserDefaults(suiteName: appGroupId),
           let savedData = sharedDefaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([WidgetDailyData].self, from: savedData) {
            data = decoded
        } else {
            // Fallback empty or mock if necessary (but usually empty)
            data = []
        }
        
        let currentDate = Date()
        let entry = WeeklyEntry(date: currentDate, data: data)
        
        // Refresh every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate) ?? currentDate.addingTimeInterval(3600)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    func mockData() -> [WidgetDailyData] {
        // Generate last 7 days mock
        var res: [WidgetDailyData] = []
        let calendar = Calendar.current
        let today = Date()
        let weekdays = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
        
        for i in 0..<7 {
           if let date = calendar.date(byAdding: .day, value: -6+i, to: today) {
               res.append(WidgetDailyData(id: UUID(), date: date, weekday: weekdays[i % 7], minutes: Double([30, 60, 45, 90, 20, 0, 15][i % 7])))
           }
        }
        return res
    }
}

struct WeeklyEntry: TimelineEntry {
    let date: Date
    let data: [WidgetDailyData]
}

struct WeeklyTrendWidgetEntryView : View {
    var entry: WeeklyEntry
    @Environment(\.widgetFamily) var family
    
    // Theme colors (Matching MindfulnessWidget)
    let gradientStart = Color(red: 0.2, green: 0.6, blue: 0.8)
    let gradientEnd = Color(red: 0.2, green: 0.8, blue: 0.7)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.caption)
                Text("正念趋势")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
            }
            
            // Chart
            GeometryReader { geo in
                if entry.data.isEmpty {
                    VStack {
                        Spacer()
                        Text("暂无数据")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                        Spacer()
                    }
                } else {
                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(entry.data) { item in
                            VStack(spacing: 4) {
                                Spacer()
                                // Bar
                                VStack {
                                    Spacer()
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.white)
                                        .frame(height: max(4, (geo.size.height - 15) * (CGFloat(item.minutes) / 120.0))) // Max 120m scale
                                        .opacity(isToday(item.date) ? 1.0 : 0.3)
                                }
                                
                                // Day Label
                                Text(String(item.weekday.prefix(1))) // First char of weekday
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white.opacity(isToday(item.date) ? 1.0 : 0.6))
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .widgetBackground(
            LinearGradient(gradient: Gradient(colors: [gradientStart, gradientEnd]), startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }
    
    func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
}

struct WeeklyTrendWidget: Widget {
    let kind: String = "WeeklyTrendWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeeklyTrendProvider()) { entry in
            WeeklyTrendWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("每周趋势")
        .description("展示过去7天的正念时长趋势。")
        .supportedFamilies([.systemSmall])
    }
}



#Preview(as: .systemSmall) {
    WeeklyTrendWidget()
} timeline: {
    WeeklyEntry(date: .now, data: WeeklyTrendProvider().mockData())
}
