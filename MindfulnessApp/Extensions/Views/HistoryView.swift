import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: MindfulnessViewModel
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.recentSessions) { session in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(session.type == .sleep ? "睡眠记录" : "正念练习")
                                .font(.headline)
                            Text(chineseDateString(session.startDate))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        // Duration Text
                        if session.type == .sleep {
                            // Sleep Format: "X小时Y分" or "X分钟"
                            Text(formatDuration(session.durationInMinutes))
                                .font(.body)
                                .foregroundColor(Color(red: 0.9, green: 0.4, blue: 0.4)) // Soft Red
                        } else {
                            // Mindfulness Format: "X 分钟"
                            Text("\(Int(session.durationInMinutes)) 分钟")
                                .font(.body)
                                .foregroundColor(.mindfulnessBlue)
                        }
                    }
                }
            }
            .navigationTitle("历史记录")
            .onAppear {
                // Refresh data when view appears
                viewModel.fetchData()
            }
        }
    }
    
    private func chineseDateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy年M月d日 HH:mm"
        return f.string(from: date)
    }
    
    private func formatDuration(_ minutes: Double) -> String {
        let m = Int(minutes)
        if m >= 60 {
            let hours = m / 60
            let mins = m % 60
            if mins == 0 {
                return "\(hours)小时"
            } else {
                return "\(hours)小时\(mins)分"
            }
        } else {
            return "\(m)分钟"
        }
    }
}

#Preview {
    HistoryView(viewModel: MindfulnessViewModel.mock)
}
