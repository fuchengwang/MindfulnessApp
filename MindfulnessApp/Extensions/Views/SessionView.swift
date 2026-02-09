import SwiftUI

struct SessionView: View {
    @ObservedObject var viewModel: MindfulnessViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var showingSaveAlert = false
    
    // Timer formatting helper
    func formatTime(seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: seconds) ?? "00:00"
    }

    var body: some View {
        ZStack {
            Color.mindfulnessPurple.opacity(0.1).ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Breathing Animation Placeholder
                Circle()
                    .fill(Color.mindfulnessTeal.opacity(0.3))
                    .frame(width: 200, height: 200)
                    .overlay(
                        Circle().stroke(Color.mindfulnessTeal, lineWidth: 2)
                    )
                    .scaleEffect(viewModel.isRecording ? 1.1 : 1.0)
                    .animation(viewModel.isRecording ? Animation.easeInOut(duration: 4).repeatForever(autoreverses: true) : .default, value: viewModel.isRecording)
                
                Spacer()
                
                Text(formatTime(seconds: viewModel.elapsedTime))
                    .font(.system(size: 64, weight: .thin, design: .monospaced))
                    .padding()
                
                Spacer()
                
                if viewModel.isRecording {
                    Button(action: {
                        viewModel.endSession()
                        showingSaveAlert = true
                    }) {
                        Text("结束")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(16)
                    }
                } else {
                    Button(action: {
                        viewModel.startSession()
                    }) {
                        Text("开始")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(16)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("正念时刻")
        .navigationBarTitleDisplayMode(.inline)
        .alert("已保存", isPresented: $showingSaveAlert) {
            Button("好的") {
                dismiss() // Go back to Summary view
            }
        }
    }
}

#Preview {
    SessionView(viewModel: MindfulnessViewModel.mock)
}
