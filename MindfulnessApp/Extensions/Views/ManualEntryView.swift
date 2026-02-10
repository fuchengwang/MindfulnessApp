import SwiftUI

struct ManualEntryView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: MindfulnessViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("Entry Mode", selection: $selectedTab) {
                    Text("刚刚").tag(0)
                    Text("指定时间").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                ScrollView {
                    if selectedTab == 0 {
                        JustNowView(viewModel: viewModel, onSaveSuccess: {
                            dismiss()
                        })
                    } else {
                        SpecificTimeView(viewModel: viewModel, onSaveSuccess: {
                            dismiss()
                        })
                    }
                }
            }
            .navigationTitle("添加记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ManualEntryView(viewModel: MindfulnessViewModel.mock)
}
