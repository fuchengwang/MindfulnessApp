import SwiftUI

struct RingView: View {
    var progress: Double // 0.0 to 1.0 (or greater)
    var goal: Double
    var width: CGFloat = 40
    var lineWidth: CGFloat = 6
    var showGoalMetAnimation: Bool = false
    
    var body: some View {
        ZStack {
            // Background Circle
            Circle()
                .stroke(Color(.systemGray6).opacity(0.5), lineWidth: lineWidth)
            
            // Progress Arc
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: progress >= 1.0 ? [.mindfulnessTeal, .mindfulnessBlue, .mindfulnessTeal] : [.mindfulnessBlue, .mindfulnessTeal]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: progress >= 1.0 ? Color.mindfulnessTeal.opacity(0.3) : .clear, radius: 3)
            
            // Overlap Arc (if > 100%) - "Turning circles" effect
            if progress > 1.0 {
                Circle()
                    .trim(from: 0, to: CGFloat(min(progress - 1.0, 1.0)))
                    .stroke(
                        Color.white, // Or a lighter shade to distinct
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    // Actually, a nice effect is just stacking another colored ring or brightening it.
                    // Let's stick to a simple overlap for now.
                    // Improving: Overlay another gradient ring.
               Circle()
                    .trim(from: 0, to: CGFloat(min(progress - 1.0, 1.0)))
                    .stroke(
                        AngularGradient(
                             gradient: Gradient(colors: [.purple, .pink]), // Distinct color for 2nd loop like Activity app
                             center: .center
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            }
        }
        .frame(width: width, height: width)
    }
}

#Preview {
    VStack(spacing: 20) {
        RingView(progress: 0.3, goal: 60, width: 50, lineWidth: 5)
        RingView(progress: 0.8, goal: 60, width: 50, lineWidth: 5)
        RingView(progress: 1.0, goal: 60, width: 50, lineWidth: 5)
        RingView(progress: 1.5, goal: 60, width: 50, lineWidth: 5)
    }
}
