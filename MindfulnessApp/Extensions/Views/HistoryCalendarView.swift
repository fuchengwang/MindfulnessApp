import SwiftUI

struct HistoryCalendarView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: MindfulnessViewModel
    @State private var showingGoalSheet = false
    @State private var tempGoal: Double = 30
    
    // Calendar Generation
    // Calendar Generation
    // Calendar Generation
    private let calendar = Calendar.current
    private let today = Date()
    private var months: [Date] {
        // Last 12 months, chronological order
        var dates: [Date] = []
        for i in 0..<12 {
            if let date = calendar.date(byAdding: .month, value: -i, to: today) {
                dates.append(date)
            }
        }
        return dates.reversed() // Past -> Current
    }
    
    // Grid Configuration
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Fixed Weekday Headers (Monday Start)
                HStack(spacing: 0) {
                    ForEach(["一", "二", "三", "四", "五", "六", "日"], id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                }
                .background(.regularMaterial) // Subtle background for sticky header effect
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                .zIndex(1) // Ensure it stays on top
                
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            ForEach(months, id: \.self) { month in
                                MonthView(month: month, viewModel: viewModel)
                                    .id(month)
                            }
                        }
                        .padding(.bottom, 20)
                        .padding(.top, 10)
                        .padding(.horizontal, 10) // Tiny horizontal padding
                    }
                    .background(Color(.systemBackground))
                    .onAppear {
                        // Scroll to current month with a slight delay to ensure layout is ready
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if let lastMonth = months.last {
                                proxy.scrollTo(lastMonth, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            .navigationTitle("历史记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        tempGoal = viewModel.dailyGoal
                        showingGoalSheet = true
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                }
            }
            .sheet(isPresented: $showingGoalSheet) {
                GoalSettingSheet(goal: $tempGoal) { newGoal in
                    viewModel.updateDailyGoal(newGoal)
                }
                .presentationDetents([.medium])
            }
        }
    }
}

struct MonthView: View {
    let month: Date
    @ObservedObject var viewModel: MindfulnessViewModel
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Month Header
            Text(monthFormatter.string(from: month))
                .font(.title3)
                .fontWeight(.bold)
                .padding(.leading, 12)
                .foregroundColor(.primary)
            
            //第一个space 修改 圆环左右间距、第二个修改上下间距
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 7), spacing: 2) { // Reduced vertical spacing
                // Days
                ForEach(daysInMonth(month), id: \.self) { date in
                    if let date = date {
                        let minutes = viewModel.historyData[calendar.startOfDay(for: date)] ?? 0
                        let progress = minutes / viewModel.dailyGoal
                        let isToday = calendar.isDateInToday(date)
                        
                        VStack(spacing: 6) { // Tighter spacing between date and ring
                            // Date Number
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 14, weight: isToday ? .bold : .medium)) // Larger font
                                .foregroundColor(isToday ? .white : .primary)
                                .frame(width: 28, height: 28) // Fixed frame for centering
                                .background(isToday ? Color.accentColor : Color.clear)
                                .clipShape(Circle())
                            
                            // Ring
                            RingView(
                                progress: progress,
                                goal: viewModel.dailyGoal,
                                width: 32, // Slightly larger
                                lineWidth: 8, // Thicker ring
                                showGoalMetAnimation: false
                            )
                        }
                        .frame(height: 72)
                    } else {
                        Color.clear
                            .frame(height: 72)
                    }
                }
            }
        }
    }
    
    private var monthFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy年 M月"
        return f
    }
    
    private func daysInMonth(_ date: Date) -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: date),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else { return [] }
        
        let weekday = calendar.component(.weekday, from: firstDay) // 1 = Sun, 2 = Mon ... 7 = Sat
        
        // Calculate offset for Monday start
        let offset = (weekday - 2 + 7) % 7
        
        var days: [Date?] = Array(repeating: nil, count: offset)
        
        for day in range {
            if let d = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(d)
            }
        }
        return days
    }
}

struct GoalSettingSheet: View {
    @Binding var goal: Double
    var onSave: (Double) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Drag Indicator
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
            
            Text("每日正念目标")
                .font(.headline)
                .padding(.bottom, 10)
            
            Spacer()
            
            // Interaction Area
            HStack(spacing: 30) {
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    if goal > 5 { goal -= 5 }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 44))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("\(Int(goal))")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    Text("分钟")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                .frame(width: 120) // Fixed width to prevent jumping
                
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    if goal < 120 { goal += 5 }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 44))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.accentColor)
                }
            }
            
            Spacer()
            
            Button(action: {
                onSave(goal)
                dismiss()
            }) {
                Text("保存设置")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.accentColor)
                    .cornerRadius(16)
                    .shadow(color: .accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .padding()
        .presentationCornerRadius(24)
        .presentationBackground(.regularMaterial)
    }
}

#Preview {
    HistoryCalendarView(viewModel: MindfulnessViewModel.mock)
}
