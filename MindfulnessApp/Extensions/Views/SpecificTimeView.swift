import SwiftUI

struct SpecificTimeView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: MindfulnessViewModel
    
    @State private var selectedDate: Date = Date()
    @State private var selectedMinutes: Double = 10
    
    let presets: [Double] = [5, 10, 15, 20, 30, 45, 60]
    
    var body: some View {
        VStack(spacing: 24) {
            // 日期时间选择器
            VStack(alignment: .leading, spacing: 12) {
                Text("选择正念时间")
                    .font(.headline)
                
                DatePicker(
                    "开始时间",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding()
            .background(Color.secondary.opacity(0.08))
            .cornerRadius(12)
            
            // 时长显示
            VStack(spacing: 8) {
                Text("正念时长")
                    .font(.headline)
                
                VStack {
                    Text("\(Int(selectedMinutes))")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(.mindfulnessBlue)
                    Text("分钟")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            
            // 快捷选择
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(presets, id: \.self) { minute in
                        Button(action: {
                            selectedMinutes = minute
                        }) {
                            Text("\(Int(minute))")
                                .font(.headline)
                                .frame(width: 55, height: 55)
                                .background(selectedMinutes == minute ? Color.mindfulnessBlue : Color.secondary.opacity(0.1))
                                .foregroundColor(selectedMinutes == minute ? .white : .primary)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // 滑块微调
            VStack {
                Slider(value: $selectedMinutes, in: 1...120, step: 1)
                    .accentColor(.mindfulnessBlue)
                HStack {
                    Text("1分钟")
                    Spacer()
                    Text("120分钟")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // 保存按钮
            Button(action: {
                viewModel.addManualSession(minutes: selectedMinutes, at: selectedDate)
                dismiss()
            }) {
                Text("记录本次正念")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(Color.mindfulnessBlue.gradient)
                    .cornerRadius(16)
                    .shadow(radius: 5)
            }
            .padding()
        }
        .padding()
    }
}

#Preview {
    SpecificTimeView(viewModel: MindfulnessViewModel.mock)
}
