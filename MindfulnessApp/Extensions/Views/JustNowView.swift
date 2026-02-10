import SwiftUI

struct JustNowView: View {
    @ObservedObject var viewModel: MindfulnessViewModel
    var onSaveSuccess: () -> Void
    
    @State private var selectedMinutes: Double = 10
    @State private var isSaving: Bool = false
    
    let presets: [Double] = [5, 10, 15, 20, 30, 45, 60]
    
    var body: some View {
        VStack(spacing: 30) {
            Text("刚刚完成了多久的正念？")
                .font(.headline)
                .padding(.top)
            
            // Time Display
            VStack {
                Text("\(Int(selectedMinutes))")
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundColor(.mindfulnessBlue)
                Text("分钟")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            // Presets
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(presets, id: \.self) { minute in
                        Button(action: {
                            selectedMinutes = minute
                        }) {
                            Text("\(Int(minute))")
                                .font(.headline)
                                .frame(width: 60, height: 60)
                                .background(selectedMinutes == minute ? Color.mindfulnessBlue : Color.secondary.opacity(0.1))
                                .foregroundColor(selectedMinutes == minute ? .white : .primary)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Slider for fine tuning
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
            .padding(.horizontal, 30)
            
            Spacer()
            
            Button(action: {
                isSaving = true
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                
                viewModel.addManualSession(minutes: selectedMinutes) { success in
                    if success {
                        // Keep isSaving = true to prevent duplicate clicks while dismissing
                        let notification = UINotificationFeedbackGenerator()
                        notification.notificationOccurred(.success)
                        onSaveSuccess()
                    } else {
                        isSaving = false
                    }
                }
            }) {
                HStack {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.trailing, 5)
                    }
                    Text(isSaving ? "正在保存..." : "记录本次正念")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 55)
                .background(isSaving ? Color.gray.gradient : Color.mindfulnessBlue.gradient)
                .cornerRadius(16)
                .shadow(radius: isSaving ? 0 : 5)
            }
            .disabled(isSaving)
            .padding()
        }
        .padding()
    }
}

#Preview {
    JustNowView(viewModel: MindfulnessViewModel.mock, onSaveSuccess: {})
}
