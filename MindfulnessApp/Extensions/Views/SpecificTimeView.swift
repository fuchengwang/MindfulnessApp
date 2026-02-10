import SwiftUI

struct SpecificTimeView: View {
    @ObservedObject var viewModel: MindfulnessViewModel
    var onSaveSuccess: () -> Void
    
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    @State private var isSaving: Bool = false
    @State private var timeScale: TimeScale = .hour1
    @State private var baseHour: Int
    
    init(viewModel: MindfulnessViewModel, onSaveSuccess: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onSaveSuccess = onSaveSuccess
        
        let now = Date()
        let start = now.addingTimeInterval(-900)
        _startTime = State(initialValue: start)
        _endTime = State(initialValue: now)
        _baseHour = State(initialValue: Calendar.current.component(.hour, from: start))
    }
    
    /// 根据刻度和当前状态计算 baseOffset
    private var baseOffset: Int {
        switch timeScale {
        case .hour1:
            return baseHour * 60
        case .hour12:
            let hour = Calendar.current.component(.hour, from: startTime)
            return hour < 12 ? 0 : 720
        case .hour24:
            return 0
        }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // 1. 头部：日期 + 刻度选择
            headerRow
            
            // 2. 小时选择（仅 hour1 模式）
            if timeScale == .hour1 {
                hourScroller
            }
            
            // 3. 圆环
            CircularTimeSlider(
                startTime: $startTime,
                endTime: $endTime,
                scale: timeScale,
                baseOffset: baseOffset
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 30)
            
            // 4. 重置按钮
            resetButton
            
            // 5. 保存按钮
            saveButton
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .onChange(of: startTime) { _ in
            // 1小时模式下，自动跟随起点所在的小时
            if timeScale == .hour1 {
                let newHour = Calendar.current.component(.hour, from: startTime)
                if newHour != baseHour {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        baseHour = newHour
                    }
                }
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            datePickerSheet
        }
    }
    
    // MARK: - 头部栏
    
    private var headerRow: some View {
        ViewThatFits(in: .horizontal) {
            // 1. 尝试使用当前系统字号
            headerContent
            
            // 2. 也是系统字号但允许稍微压缩（利用 minimumScaleFactor）
            headerContent
                .minimumScaleFactor(0.9)
            
            // 3. 限制最大为 辅助功能3 (Accessibility3)
            headerContent
                .dynamicTypeSize(...DynamicTypeSize.accessibility3)
            
            // 4. 限制最大为 辅助功能1 (Accessibility1)
            headerContent
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            
            // 5. 限制最大为 XXXLarge (人体工学极限)
            headerContent
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            
            // 6. 限制最大为 Large (标准大)
            headerContent
                .dynamicTypeSize(...DynamicTypeSize.large)
            
            // 7. 最后的保底：允许在 Large 基础上进一步从整体上缩放
            headerContent
                .dynamicTypeSize(...DynamicTypeSize.large)
                .minimumScaleFactor(0.5)
        }
    }
    
    private var headerContent: some View {
        HStack {
            // 日期选择
            Button(action: { showingDatePicker = true }) {
                HStack(spacing: 5) {
                    Image(systemName: "calendar")
                        .foregroundColor(.mindfulnessBlue)
                        .font(.system(size: 14))
                    Text(formattedDate(selectedDate))
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.primary)
                        .bold()
                        .lineLimit(1)
                        .fixedSize() // 确保文字完整显示，不被压缩（通过 ViewThatFits 换别的尺寸）
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6))
                .cornerRadius(16)
            }
            
            Spacer()
            
            // 刻度下拉
            Menu {
                ForEach(TimeScale.allCases, id: \.self) { s in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            timeScale = s
                        }
                    }) {
                        HStack {
                            Text(s.rawValue)
                            if s == timeScale {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "dial.low.fill")
                        .font(.system(size: 12))
                    Text(timeScale.rawValue)
                        .font(.system(.subheadline, design: .rounded))
                        .bold()
                        .lineLimit(1)
                        .fixedSize() // 确保文字完整显示
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 8, weight: .bold))
                }
                .foregroundColor(.mindfulnessBlue)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Color.mindfulnessBlue.opacity(0.1))
                .cornerRadius(16)
            }
        }
    }
    
    // MARK: - 小时横向选择器
    
    private var hourScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { proxy in
                HStack(spacing: 8) {
                    ForEach(0..<24, id: \.self) { hour in
                        let isSelected = baseHour == hour
                        Text("\(hour)时")
                            .font(.system(size: 13, weight: isSelected ? .bold : .regular, design: .rounded))
                            .foregroundColor(isSelected ? .white : .primary)
                            .frame(width: 42, height: 28)
                            .background(isSelected ? Color.mindfulnessBlue : Color(.systemGray6))
                            .cornerRadius(14)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    updateBaseHour(to: hour)
                                }
                            }
                            .id(hour)
                    }
                }
                .padding(.horizontal, 12)
                .onAppear {
                    proxy.scrollTo(baseHour, anchor: .center)
                }
            }
        }
        .frame(height: 34)
    }
    
    // MARK: - 保存按钮
    
    private var saveButton: some View {
        Button(action: saveAction) {
            HStack {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.trailing, 4)
                }
                Text(isSaving ? "正在保存..." : "保存记录")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isSaving ? Color.gray.gradient : Color.mindfulnessBlue.gradient)
            .cornerRadius(14)
//            .shadow(radius: isSaving ? 0 : 4)
        }
        .disabled(isSaving)
    }
    
    // MARK: - 重置按钮
    
    private var resetButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                resetToDefault()
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 12, weight: .medium))
                Text("重置时间")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
            }
            .foregroundStyle(Color(.tertiaryLabel))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .cornerRadius(14)
        }
    }
    
    // MARK: - 日期选择 Sheet
    
    private var datePickerSheet: some View {
        VStack {
            Spacer()
            DatePicker(
                "选择日期",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .padding()
            .environment(\.locale, Locale(identifier: "zh_CN"))
            
            Button("确定") {
                showingDatePicker = false
            }
            .font(.headline)
            .foregroundColor(.mindfulnessBlue)
            .padding()
        }
        .presentationDetents([.medium])
        
    }
    
    // MARK: - 逻辑
    
    private func saveAction() {
        isSaving = true
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        let finalStart = combineDateAndTime(date: selectedDate, time: startTime)
        var finalEnd = combineDateAndTime(date: selectedDate, time: endTime)
        
        // 跨午夜处理
        if finalEnd <= finalStart {
            finalEnd = Calendar.current.date(byAdding: .day, value: 1, to: finalEnd) ?? finalEnd
        }
        
        viewModel.saveSpecificSession(start: finalStart, end: finalEnd) { success in
            if success {
                let notification = UINotificationFeedbackGenerator()
                notification.notificationOccurred(.success)
                onSaveSuccess()
            } else {
                isSaving = false
            }
        }
    }
    
    private func updateBaseHour(to newHour: Int) {
        let diff = newHour - baseHour
        baseHour = newHour
        if let newStart = Calendar.current.date(byAdding: .hour, value: diff, to: startTime),
           let newEnd = Calendar.current.date(byAdding: .hour, value: diff, to: endTime) {
            startTime = newStart
            endTime = newEnd
        }
    }
    
    /// 重置为默认状态（起=当前时间-15分钟，止=当前时间）
    private func resetToDefault() {
        let now = Date()
        let start = now.addingTimeInterval(-900)
        startTime = start
        endTime = now
        baseHour = Calendar.current.component(.hour, from: start)
    }
    
    // MARK: - 工具
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }
    
    private func combineDateAndTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComps = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComps = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(from: DateComponents(
            year: dateComps.year,
            month: dateComps.month,
            day: dateComps.day,
            hour: timeComps.hour,
            minute: timeComps.minute
        )) ?? time
    }
}

#Preview {
    SpecificTimeView(viewModel: MindfulnessViewModel.mock, onSaveSuccess: {})
}
