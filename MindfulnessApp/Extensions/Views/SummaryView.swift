import SwiftUI
import Charts

struct SummaryView: View {
    @ObservedObject var viewModel: MindfulnessViewModel
    @State private var isShowingManualEntry = false
    @State private var showingHistory = false
    @State private var showSettings = false
    @State private var showSleepRecord = false
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
                    
                    // Quick Action: Start Mindfulness
                    Button(action: {
                        isShowingManualEntry = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("记录正念")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.mindfulnessBlue.gradient)
                        .cornerRadius(16)
                        .shadow(radius: 4)
                    }
                    
                    if viewModel.showSleepRecording {
                        Button(action: {
                            showSleepRecord = true
                        }) {
                            HStack {
                                Image(systemName: "moon.fill")
                                    .font(.title2)
                                Text("记录睡眠")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.85, green: 0.4, blue: 0.4).gradient) // Softer Red
                            .cornerRadius(16)
                            .shadow(radius: 4)
                        }
                    }
                }
                .padding()
            }
            .background(Color.backgroundGray)
            .navigationTitle("摘要")
            .overlay(alignment: .bottom) {
                if viewModel.showSleepToast {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("已添加记录")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(viewModel.sleepToastMessage)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Spacer()
                        Button("撤回") {
                            viewModel.undoSleepSave()
                        }
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                    }
                    .padding()
                    .background(Color.black.opacity(0.85))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(100)
                }
            }
            .onAppear {
                viewModel.requestAuthorization()
                viewModel.fetchData()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "person.crop.circle")
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
            .sheet(isPresented: $showSettings) {
                SettingsView(viewModel: viewModel)
            }
            .sheet(isPresented: $showSleepRecord) {
                SleepRecordView(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    SummaryView(viewModel: MindfulnessViewModel.mock)
}
