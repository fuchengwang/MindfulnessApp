import SwiftUI

struct RingView: View {
    var progress: Double // 0.0 ~ ∞（minutes / goal）
    var goal: Double
    var width: CGFloat = 40
    var lineWidth: CGFloat = 6
    var showGoalMetAnimation: Bool = false
    
    // 从 Widget 提取的配色方案
    // Start: Color(red: 0.2, green: 0.6, blue: 0.8) -> 明亮蓝
    // End:   Color(red: 0.2, green: 0.8, blue: 0.7) -> 青绿
    private let widgetBlue = Color(red: 0.2, green: 0.6, blue: 0.8)
    private let widgetTeal = Color(red: 0.2, green: 0.8, blue: 0.7)
    
    var body: some View {
        ZStack {
            // 背景轨道
            Circle()
                .stroke(Color(.systemGray6).opacity(0.5), lineWidth: lineWidth)
            
            if progress > 1.0 {
                // ── 超过目标 (>=100%) ──
                
                // 第一圈（底层完整圈）：完整的蓝→青渐变
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [widgetBlue, widgetTeal]),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                // 溢出弧（上层）：使用更亮的青色叠加，形成“高亮”效果
                // 进度：progress - 1.0 (例如 1.2 -> 0.2)
                Circle()
                    .trim(from: 0, to: CGFloat(min(progress - 1.0, 1.0)))
                    .stroke(
                        widgetTeal.opacity(0.6), // 半透明叠加会让颜色更深/更亮
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: widgetTeal.opacity(0.4), radius: 3)
                
            } else {
                // ── 未达标 (<100%) ──
                
                // 进度弧：蓝→青渐变
                // 为了保证渐变色完整性，我们绘制一个满圈的渐变，然后用 trim 截取
                // 这样 50% 进度时显示的是 蓝→中间色，而不是 蓝→青 被压缩在半圈里
                Circle()
                    .trim(from: 0, to: CGFloat(max(progress, 0)))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [widgetBlue, widgetTeal]),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
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
        RingView(progress: 0.1, goal: 15, width: 50, lineWidth: 8)  // 刚开始
        RingView(progress: 0.33, goal: 15, width: 50, lineWidth: 8) // 三分之一
        RingView(progress: 0.66, goal: 15, width: 50, lineWidth: 8) // 三分之二
        RingView(progress: 1.0, goal: 15, width: 50, lineWidth: 8)  // 达标 (完整青色)
        RingView(progress: 1.5, goal: 15, width: 50, lineWidth: 8)  // 超标 (青色叠加)
        RingView(progress: 2.5, goal: 15, width: 50, lineWidth: 8)  // 超标多圈
    }
}
