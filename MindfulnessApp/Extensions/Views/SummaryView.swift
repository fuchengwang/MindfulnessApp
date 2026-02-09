import SwiftUI
import Charts

struct SummaryView: View {
    @ObservedObject var viewModel: MindfulnessViewModel
    @State private var isShowingManualEntry = false
    @State private var showingHistory = false
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Today's Summary Card
                    CardView {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("今日专注")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                HStack(alignment: .lastTextBaseline, spacing: 4) {
                                    Text("\(Int(viewModel.totalMinutesToday))")
                                        .font(.system(size: 48, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    
                                    Text("分钟")
                                        .font(.title3)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 40))
                                .foregroundColor(.mindfulnessTeal)
                        }
                    }
                    
                    // Weekly Trend Chart
                    CardView {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("本周趋势")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button(action: {
                                    showingHistory = true
                                }) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 20))
                                        .foregroundColor(.mindfulnessBlue)
                                }
                            }
                            
                            if !viewModel.weeklyData.isEmpty {
                                Chart(viewModel.weeklyData) { day in
                                    BarMark(
                                        x: .value("Day", day.weekday),
                                        y: .value("Minutes", day.minutes)
                                    )
                                    .foregroundStyle(Color.mindfulnessBlue.gradient)
                                    .cornerRadius(6)
                                }
                                .frame(height: 180)
                                .chartYAxis {
                                    AxisMarks(position: .leading, values: .automatic) { value in
                                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                            .foregroundStyle(Color.secondary.opacity(0.15))
                                        
                                        AxisValueLabel {
                                            if let intValue = value.as(Int.self) {
                                                Text("\(intValue)分")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                                .chartXAxis {
                                    AxisMarks(values: .automatic) { value in
                                        if let day = value.as(String.self) {
                                            // Extract short day name (e.g., "周一" -> "一")
                                            let shortDay = day.replacingOccurrences(of: "周", with: "")
                                            // Use short name if font size is large to prevent truncation
                                            let label = dynamicTypeSize > .large ? shortDay : day
                                            
                                            AxisValueLabel {
                                                Text(label)
                                                    .font(.caption)
                                                    .foregroundStyle(Color.secondary)
                                            }
                                        }
                                    }
                                }
                            } else {
                                Text("加载中...")
                                    .foregroundColor(.secondary)
                                    .frame(height: 200)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    
                    // Quick Action: Start Session
                    /*
                    NavigationLink(destination: SessionView(viewModel: viewModel)) {
                        HStack {
                            Text("开始正念")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "play.circle.fill")
                                .font(.title)
                        }
                        .padding()
                        .background(Color.mindfulnessBlue.gradient)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(radius: 5)
                       
                        
                    }*/
                }
                .padding()
            }
            .background(Color.backgroundGray)
            .navigationTitle("摘要")
            .onAppear {
                viewModel.requestAuthorization()
                viewModel.fetchData()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingManualEntry = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.mindfulnessBlue)
                    }
                }
            }
            .sheet(isPresented: $isShowingManualEntry) {
                ManualEntryView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingHistory) {
                HistoryCalendarView(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    SummaryView(viewModel: MindfulnessViewModel.mock)
}
