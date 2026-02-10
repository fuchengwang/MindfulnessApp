import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: MindfulnessViewModel
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.recentSessions) { session in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("正念练习")
                                .font(.headline)
                            Text(chineseDateString(session.startDate))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(Int(session.durationInMinutes)) 分钟")
                            .font(.body)
                            .foregroundColor(.mindfulnessBlue)
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
}

#Preview {
    HistoryView(viewModel: MindfulnessViewModel.mock)
}
