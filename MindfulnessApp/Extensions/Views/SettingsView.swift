import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: MindfulnessViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("目标设定")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("每日正念目标: \(Int(viewModel.dailyGoal)) 分钟")
                            .font(.headline)
                        
                        Slider(value: $viewModel.dailyGoal, in: 5...120, step: 5) {
                            Text("目标")
                        } minimumValueLabel: {
                            Text("5")
                        } maximumValueLabel: {
                            Text("120")
                        }
                        .tint(.mindfulnessBlue)
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("功能开关")) {
                    Toggle(isOn: $viewModel.showSleepRecording) {
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundColor(.indigo)
                            Text("记录每日睡眠数据")
                        }
                    }
                }
                
                Section(header: Text("关于")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("完成")
                            .fontWeight(.bold)
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView(viewModel: MindfulnessViewModel.mock)
}
