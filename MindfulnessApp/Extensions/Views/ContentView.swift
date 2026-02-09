import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = MindfulnessViewModel()
    
    var body: some View {
        TabView {
            SummaryView(viewModel: viewModel)
                .tabItem {
                    Label("摘要", systemImage: "heart.text.square.fill")
                }
            
            HistoryView(viewModel: viewModel)
                .tabItem {
                    Label("历史", systemImage: "clock.fill")
                }
        }
        .accentColor(.mindfulnessBlue)
    }
}

#Preview {
    ContentView(viewModel: MindfulnessViewModel.mock)
}
