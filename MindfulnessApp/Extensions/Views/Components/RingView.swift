import SwiftUI

struct RingView: View {
    var progress: Double // 0.0 ~ ∞（minutes / goal）
    var goal: Double
    var width: CGFloat = 40
    var lineWidth: CGFloat = 6
    var showGoalMetAnimation: Bool = false
    
    // 计算当前进度对应的渐变色（蓝→红，按 progress 插值）
    private var progressColor: Color {
        // 0% = 蓝(mindfulnessBlue)  100% = 深红
        let t = min(max(progress, 0), 1.0)
        // HSB 插值：蓝(210°) → 红(0°/360°)
        let startHue: Double = 210.0 / 360.0   // 蓝
        let endHue: Double = 0.0 / 360.0        // 红
        // 走短程路径：210° → 360°(=0°)，即 hue 递增
        let hue = startHue + (1.0 - startHue + endHue) * t // 210 → 360
        let normalizedHue = hue.truncatingRemainder(dividingBy: 1.0)
        return Color(hue: normalizedHue, saturation: 0.7 + 0.15 * t, brightness: 0.85)
    }
    
    // 终点色（100% 时的颜色 = 深红）
    private var goalColor: Color {
        Color(hue: 0.0 / 360.0, saturation: 0.85, brightness: 0.85)
    }
    
    var body: some View {
        ZStack {
            // 背景轨道
            Circle()
                .stroke(Color(.systemGray6).opacity(0.5), lineWidth: lineWidth)
            
            if progress > 1.0 {
                // ── 超过目标：底层完整圈用深红，上层溢出弧也用深红（略亮） ──
                
                // 第一圈（完整） — 深红
                Circle()
                    .trim(from: 0, to: 1.0)
                    .stroke(
                        goalColor,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                // 溢出弧 — 保持深红，略加透明叠加效果
                Circle()
                    .trim(from: 0, to: CGFloat(min(progress - 1.0, 1.0)))
                    .stroke(
                        goalColor.opacity(0.9),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    // .shadow(color: goalColor.opacity(0.4), radius: 3)
                
            } else {
                // ── 未达标：蓝→红渐变弧 ──
                Circle()
                    .trim(from: 0, to: CGFloat(max(progress, 0)))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: gradientColors()),
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
    
    /// 根据 progress 生成蓝→当前色的渐变色数组
    private func gradientColors() -> [Color] {
        let startColor = Color.mindfulnessBlue
        let endColor = progressColor
        // 简单两色渐变
        return [startColor, endColor]
    }
}

#Preview {
    VStack(spacing: 20) {
        RingView(progress: 0.1, goal: 15, width: 50, lineWidth: 8)  // 微蓝
        RingView(progress: 0.33, goal: 15, width: 50, lineWidth: 8) // 蓝偏紫
        RingView(progress: 0.66, goal: 15, width: 50, lineWidth: 8) // 偏红
        RingView(progress: 1.0, goal: 15, width: 50, lineWidth: 8)  // 深红
        RingView(progress: 1.5, goal: 15, width: 50, lineWidth: 8)  // 超标
        RingView(progress: 2.5, goal: 15, width: 50, lineWidth: 8)  // 超标多圈
    }
}
