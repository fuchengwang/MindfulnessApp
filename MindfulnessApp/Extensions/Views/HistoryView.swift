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
                            Text(session.startDate.formatted(date: .abbreviated, time: .shortened))
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
}

#Preview {
    HistoryView(viewModel: MindfulnessViewModel.mock)
}
