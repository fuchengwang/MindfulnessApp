import SwiftUI

struct SleepRecordView: View {
    @ObservedObject var viewModel: MindfulnessViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    @State private var isSaving: Bool = false
    
    // Soft Red Color
    private let softRed = Color(red: 0.9, green: 0.4, blue: 0.4)
    
    init(viewModel: MindfulnessViewModel) {
        self.viewModel = viewModel
        
        // Defaults: Sleep at 23:00 yesterday, Wake at 07:00 today
        let now = Date()
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 7
        components.minute = 0
        let todaySevenAM = calendar.date(from: components) ?? now
        let yesterdayElevenPM = calendar.date(byAdding: .hour, value: -8, to: todaySevenAM) ?? now
        
        _startTime = State(initialValue: yesterdayElevenPM)
        _endTime = State(initialValue: todaySevenAM)
        // Ensure selectedDate matches the "end" date usually (morning)
        _selectedDate = State(initialValue: now)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                // 1. Header: Date Picker
                headerRow
                
                // 2. Circular Slider
                CircularTimeSlider(
                    startTime: $startTime,
                    endTime: $endTime,
                    scale: .hour24,
                    baseOffset: 0,
                    primaryColor: softRed,
                    gradientColors: [
                        softRed.opacity(0.8),
                        softRed.opacity(0.6), // Simplified
                        softRed.opacity(0.9),
                        softRed.opacity(0.8),
                        softRed.opacity(0.8)
                    ],
                    allowMultiLap: false,
                    dateLabelProvider: { date in
                        getRelativeDateString(date)
                    },
                    showTimeLabels: false,       // Hide "Start"/"End"
                    dateLabelFontSize: 14        // Larger date font
                )
                .padding(.horizontal, 12)
                .padding(.top, 30)
                .padding(.bottom, -10)
                
                Spacer()
                
                // 3. Save Button
                saveButton
                    .padding()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            .navigationTitle("睡眠记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                datePickerSheet
            }
            .onChange(of: selectedDate) { newDate in
                syncTimesToDate(newDate)
            }
        }
    }
    
    private func syncTimesToDate(_ date: Date) {
        let calendar = Calendar.current
        // Calculate duration and relative start offset
        let duration = endTime.timeIntervalSince(startTime)
        
        // Anchor End Time to the new Date (preserve hour/minute)
        let endComp = calendar.dateComponents([.hour, .minute], from: endTime)
        guard let newEnd = calendar.date(bySettingHour: endComp.hour ?? 0, minute: endComp.minute ?? 0, second: 0, of: date) else { return }
        
        // Update End Time
        endTime = newEnd
        // Update Start Time relative to new End Time
        startTime = newEnd.addingTimeInterval(-duration)
    }
    
    // MARK: - Header
    private var headerRow: some View {
        HStack {
            // Date Picker Button
            Button(action: { showingDatePicker = true }) {
                HStack(spacing: 5) {
                    Image(systemName: "calendar")
                        .foregroundColor(softRed)
                        .font(.system(size: 14))
                    Text("醒来日期: " + formattedDate(selectedDate))
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.primary)
                        .bold()
                        .lineLimit(1)
                        .fixedSize()
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
        }
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: saveAction) {
            HStack {
                 if isSaving {
                     ProgressView()
                         .progressViewStyle(CircularProgressViewStyle(tint: .white))
                         .padding(.trailing, 4)
                 }
                Text(isSaving ? "正在保存..." : "添加睡眠记录")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isSaving ? Color.gray.gradient : softRed.gradient)
            .cornerRadius(14)
            .shadow(radius: isSaving ? 0 : 4)
        }
        .disabled(isSaving)
    }
    
    // MARK: - Date Picker Sheet
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
            .foregroundColor(softRed)
            .padding()
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Helpers
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }
    
    private func getRelativeDateString(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let dateDay = calendar.startOfDay(for: date)
        let nowDay = calendar.startOfDay(for: now)
        
        let components = calendar.dateComponents([.day], from: nowDay, to: dateDay)
        let dayDiff = components.day ?? 0
        
        if dayDiff == 0 {
            return "今天"
        } else if dayDiff == -1 {
            return "昨天"
        } else {
            // Future or older past -> Date
            let f = DateFormatter()
            f.dateFormat = "M月d日"
            return f.string(from: date)
        }
    }
    
    var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }
    
    // MARK: - Logic
    func saveAction() {
        isSaving = true
        
        // Prepare data description
        let desc = "\(timeFormatter.string(from: startTime)) - \(timeFormatter.string(from: endTime))"
        
        // Calculate final Dates
        // Logic: End time is on Selected Date. Start time is relative to End time.
        // If Start > End (e.g. 23:00 > 07:00), Start is Yesterday.
        // CircularTimeSlider handles the date components in `startTime` and `endTime` bindings relative to each other?
        // Actually CircularTimeSlider updates the `Date` objects directly.
        // So `startTime` and `endTime` already have the correct relative time difference.
        // We just need to anchor them to the `selectedDate`.
        
        let calendar = Calendar.current
        
        // Get Time Components from the slider's dates
        let startComp = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComp = calendar.dateComponents([.hour, .minute], from: endTime)
        
        // Anchor End Time to Selected Date
        var finalEnd = calendar.date(bySettingHour: endComp.hour ?? 0, minute: endComp.minute ?? 0, second: 0, of: selectedDate) ?? selectedDate
        
        // If the slider implies next day (cross midnight), `endTime` in slider might be next day relative to `startTime`.
        // But here we want `endTime` to be the `selectedDate` (morning).
        // So `startTime` should be calculated by subtracting duration.
        
        let duration = endTime.timeIntervalSince(startTime)
        // If duration is negative, add 24h (though slider should handle this if logic is correct)
        // CircularTimeSlider's `updateTime` updates the actual date object.
        // Let's trust the duration from the slider dates.
        
        let finalStart = finalEnd.addingTimeInterval(-duration)
        
        // Call ViewModel to handle toast and save
        viewModel.preSaveSleep(start: finalStart, end: finalEnd, message: desc)
        
        // Dismiss immediately
        dismiss()
    }
}

// MARK: - 24H Circular Slider


