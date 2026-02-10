import SwiftUI

/// 圆环时间刻度
enum TimeScale: String, CaseIterable {
    case hour1 = "1小时"
    case hour12 = "半天"
    case hour24 = "全天"
    
    var totalMinutes: Double {
        switch self {
        case .hour1: return 60
        case .hour12: return 720
        case .hour24: return 1440
        }
    }
    
    var stepDegrees: Double {
        switch self {
        case .hour1: return 6.0
        case .hour12: return 2.5
        case .hour24: return 1.25
        }
    }
}

// MARK: - 圆环时间选择器

/// iOS 17 原生风格圆环选择器，支持多圈
struct CircularTimeSlider: View {
    @Binding var startTime: Date
    @Binding var endTime: Date
    var scale: TimeScale = .hour1
    var baseOffset: Int = 0

    
    // ── 样式常量 ──
    private let trackWidth: CGFloat = 24
    private let knobDiameter: CGFloat = 34
    
    // ── 拖拽状态 ──
    @State private var startAngle: Double = 0
    @State private var endAngle: Double = 0
    @State private var extraLaps: Int = 0           // 额外圈数
    @State private var previousEndAngle: Double = 0 // 检测越过起点
    @State private var dragComponent: DragComponent? = nil
    @State private var dragStartAngle: Double = 0
    @State private var initialStartAngle: Double = 0
    @State private var initialEndAngle: Double = 0
    
    private let feedback = UISelectionFeedbackGenerator()
    
    enum DragComponent { case start, end, interval }
    
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = (size - trackWidth) / 2 - 10
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            
            ZStack {
                // ① 轨道凹槽 - 拟物化
                trackGroove(size: size, radius: radius)
                
                // ② 刻度 - 内侧
                ticks(at: radius - trackWidth / 2 - 8)
                
                // ③ 时间标注
                labels(at: radius - trackWidth / 2 - 28, dialSize: size)
                
                // ④ 选中弧线 - 多圈统一叠加
                activeTimeArc(center: center, radius: radius)
                
                // ⑤ 手柄
                knob(text: "起", angle: startAngle, radius: radius)
                knob(text: "止", angle: endAngle, radius: radius)
                
                // ⑥ 中央面板
                centerPanel(fitWidth: radius * 1.3)
            }
            .compositingGroup()
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in onDrag(v, center: center) }
                    .onEnded { _ in
                        dragComponent = nil
                        syncAnglesFromDates() // 拖拽结束后重新同步角度
                    }
            )
            .onAppear {
                feedback.prepare()
                syncAnglesFromDates()
            }
            .onChange(of: startTime)  { _ in if dragComponent == nil { syncAnglesFromDates() } }
            .onChange(of: endTime)    { _ in if dragComponent == nil { syncAnglesFromDates() } }
            .onChange(of: scale)      { _ in extraLaps = 0; syncAnglesFromDates() }
            .onChange(of: baseOffset) { _ in if dragComponent == nil { syncAnglesFromDates() } }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    // MARK: ──────────────────────── 视觉层 ────────────────────────
    
    /// ① 轨道 — 深邃凹槽
    private func trackGroove(size: CGFloat, radius: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color(.systemGray5),
                            Color(.systemGray6),
                            Color(.systemGray5)
                        ]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    lineWidth: trackWidth
                )
                .frame(width: radius * 2, height: radius * 2)
            
            // 顶部高光
            Circle()
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                .frame(width: radius * 2 + trackWidth, height: radius * 2 + trackWidth)
                .mask(
                    Circle()
                        .stroke(lineWidth: trackWidth)
                        .frame(width: radius * 2, height: radius * 2)
                )
            
            // 底部阴影
            Circle()
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
                .frame(width: radius * 2 - trackWidth, height: radius * 2 - trackWidth)
                .mask(
                    Circle()
                        .stroke(lineWidth: trackWidth)
                        .frame(width: radius * 2, height: radius * 2)
                )
        }
    }
    
    /// ④ 选中弧线 - 多圈统一叠加
    private func activeTimeArc(center: CGPoint, radius: CGFloat) -> some View {
        ZStack {
            // 1. 绘制已经跑完的整圈 (每圈透明度叠加)
            ForEach(0..<extraLaps, id: \.self) { _ in
                gradientArc(center: center, radius: radius, start: startAngle, end: startAngle + 360)
            }
            
            // 2. 绘制当前正在跑的那一段
            gradientArc(center: center, radius: radius, start: startAngle, end: endAngle)
        }
    }

    /// 通用渐变弧线生成器
    private func gradientArc(center: CGPoint, radius: CGFloat, start: Double, end: Double) -> some View {
        // 使用循环渐变色 (Head == Tail) 确保首尾无缝衔接
        let gradient = AngularGradient(
            gradient: Gradient(colors: [
                Color.mindfulnessBlue.opacity(0.8), // 起点
                Color.cyan.opacity(0.9),            // 中间提亮
                Color.blue.opacity(0.9),            // 过渡
                Color.mindfulnessBlue.opacity(0.8)  // 回归起点 (闭环)
            ]),
            center: .center,
            startAngle: .degrees(start - 90),       // 渐变起始角度跟随弧线起点
            endAngle: .degrees(start - 90 + 360)    // 渐变拉伸一整圈
        )
        
        return Path { p in
            p.addArc(
                center: center, radius: radius,
                startAngle: .degrees(start - 90),
                endAngle:   .degrees(end - 90),
                clockwise: false
            )
        }
        .stroke(
            gradient,
            style: StrokeStyle(lineWidth: trackWidth - 6, lineCap: .round)
        )
        // 固定基础透明度，利用 ZStack 叠加产生变深效果
        .opacity(0.6) 
        .shadow(color: Color.mindfulnessBlue.opacity(0.3), radius: 6, x: 0, y: 0)
    }
    
    /// ⑤ 手柄 — 浮起的瓷白色按钮
    private func knob(text: String, angle: Double, radius: CGFloat) -> some View {
        let rad = (angle - 90) * .pi / 180
        return ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.white, Color(.systemGray6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Circle()
                .strokeBorder(Color.white, lineWidth: 2)
                .shadow(color: .black.opacity(0.1), radius: 1)
            
            Text(text)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.mindfulnessBlue)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(width: knobDiameter, height: knobDiameter)
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 3)
        .offset(x: radius * cos(rad), y: radius * sin(rad))
    }
    
    /// ② 刻度
    private func ticks(at r: CGFloat) -> some View {
        let cfg = tickCfg
        return ZStack {
            ForEach(0..<cfg.total, id: \.self) { i in
                let deg = Double(i) / Double(cfg.total) * 360
                let major = i % cfg.majorEvery == 0
                
                if major {
                    Capsule()
                        .fill(Color.primary.opacity(0.3))
                        .frame(width: 2, height: 6)
                        .offset(y: -r)
                        .rotationEffect(.degrees(deg))
                } else {
                    Circle()
                        .fill(Color.primary.opacity(0.15))
                        .frame(width: 2, height: 2)
                        .offset(y: -r)
                        .rotationEffect(.degrees(deg))
                }
            }
        }
    }
    
    private var tickCfg: (total: Int, majorEvery: Int) {
        switch scale {
        case .hour1:  return (60, 5)
        case .hour12: return (48, 4)
        case .hour24: return (48, 2)
        }
    }
    
    /// ③ 数字标注
    private func labels(at r: CGFloat, dialSize: CGFloat) -> some View {
        let sz: CGFloat = dialSize < 260 ? 10 : 12
        return ZStack {
            ForEach(labelData, id: \.angle) { item in
                let rad = (item.angle - 90) * .pi / 180
                Text(item.text)
                    .font(.system(size: sz, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(.secondaryLabel))
                    .position(x: r * cos(rad), y: r * sin(rad))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(width: 0, height: 0)
    }
    
    private var labelData: [LabelItem] {
        switch scale {
        case .hour1:
            let h = (baseOffset / 60) % 24
            return [0, 15, 30, 45].map {
                LabelItem(angle: Double($0) / 60 * 360, text: String(format: "%d:%02d", h, $0))
            }
        case .hour12:
            let base = (baseOffset / 60) % 24
            return (0..<6).map { i in
                LabelItem(angle: Double(i) / 6 * 360, text: "\((base + i * 2) % 24)")
            }
        case .hour24:
            return [0,3,6,9,12,15,18,21].map {
                LabelItem(angle: Double($0) / 24 * 360, text: "\($0)")
            }
        }
    }
    
    /// ⑥ 中央面板
    private func centerPanel(fitWidth: CGFloat) -> some View {
        VStack(spacing: 6) {
            // 时间行
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 0) {
                    timeColumn(label: "开始", time: startTime)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(.quaternaryLabel))
                        .padding(.horizontal, 6)
                    
                    timeColumn(label: "结束", time: endTime)
                }
                
                VStack(spacing: 4) {
                    timeColumn(label: "开始", time: startTime)
                    Image(systemName: "arrow.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(.quaternaryLabel))
                    timeColumn(label: "结束", time: endTime)
                }
            }
            .layoutPriority(1)
            
            // 时长胶囊
            durationBadge
            

        }
        .frame(maxWidth: fitWidth)
        .minimumScaleFactor(0.4)
    }
    
    private func timeColumn(label: String, time: Date) -> some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(.tertiaryLabel))
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(fmtTime(time))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary)
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .minimumScaleFactor(0.8)
        }
    }
    
    @ViewBuilder
    private var durationBadge: some View {
        let mins = durationMinutes()
        let h = Int(mins) / 60, m = Int(mins) % 60
        let text = h > 0 ? "\(h)小时\(m)分钟" : "\(m)分钟"
        
        Text(text)
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.mindfulnessBlue)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.mindfulnessBlue.opacity(0.1))
            )
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }
    
    // MARK: ──────────────────────── 交互逻辑 ────────────────────────
    
    private func onDrag(_ value: DragGesture.Value, center: CGPoint) {
        let dx = value.location.x - center.x
        let dy = value.location.y - center.y
        var a = atan2(dy, dx) * 180 / .pi + 90
        if a < 0 { a += 360 }
        
        if dragComponent == nil {
            let sd = abs(adiff(a, startAngle))
            let ed = abs(adiff(a, endAngle))
            if sd < 28      { dragComponent = .start }
            else if ed < 28  { dragComponent = .end }
            else if inArc(a) {
                dragComponent = .interval
                dragStartAngle = a; initialStartAngle = startAngle; initialEndAngle = endAngle
            }
            previousEndAngle = endAngle
        }
        guard let c = dragComponent else { return }
        let step = scale.stepDegrees
        var snap = round(a / step) * step
        if snap >= 360 { snap -= 360 }
        
        switch c {
        case .start:
            guard snap != startAngle else { return }
            // 使用角度差值直接计算时间变化量，避免绝对映射的反馈环问题
            let deltaAngle = adiff(snap, startAngle)
            let deltaSecs = deltaAngle / 360 * scale.totalMinutes * 60
            feedback.selectionChanged()
            startAngle = snap
            startTime = startTime.addingTimeInterval(deltaSecs)
            
        case .end:
            guard snap != endAngle else { return }
            
            // 检测是否越过起点（多圈逻辑）
            let oldArcLen = arcLength(from: startAngle, to: previousEndAngle)
            let newArcLen = arcLength(from: startAngle, to: snap)
            
            if oldArcLen > 270 && newArcLen < 90 {
                extraLaps += 1
            } else if oldArcLen < 90 && newArcLen > 270 && extraLaps > 0 {
                extraLaps -= 1
            }
            
            previousEndAngle = snap
            feedback.selectionChanged()
            endAngle = snap
            pushEndDate()
            
        case .interval:
            let target = round((initialStartAngle + adiff(a, dragStartAngle)) / step) * step
            guard target != startAngle else { return }
            let delta = adiff(target, startAngle)
            let deltaSecs = delta / 360 * scale.totalMinutes * 60
            feedback.selectionChanged()
            startAngle = target
            endAngle = (endAngle + delta).truncatingRemainder(dividingBy: 360)
            if endAngle < 0 { endAngle += 360 }
            previousEndAngle = endAngle
            startTime = startTime.addingTimeInterval(deltaSecs)
            endTime = endTime.addingTimeInterval(deltaSecs)
        }
    }
    
    /// 计算从 from 到 to 顺时针的弧长（0~360）
    private func arcLength(from: Double, to: Double) -> Double {
        var d = to - from
        if d < 0 { d += 360 }
        return d
    }
    
    // MARK: ──────────────────────── 数据同步 ────────────────────────
    
    /// 仅用于终点手柄：根据角度绝对映射到时间
    private func pushEndDate() {
        let cal = Calendar.current
        let periodMinutes = Int(scale.totalMinutes)
        var m = (Int((endAngle / 360) * scale.totalMinutes) + baseOffset) % 1440
        // 多圈模式：加上额外圈数
        m += extraLaps * periodMinutes
        // 非多圈时终点越过起点需加一个周期
        if extraLaps == 0 && endAngle < startAngle {
            m += periodMinutes
        }
        m = ((m % 1440) + 1440) % 1440
        endTime = cal.date(bySettingHour: m/60, minute: m%60, second: 0, of: endTime) ?? endTime
    }
    
    private func syncAnglesFromDates() {
        let cal = Calendar.current
        let s = cal.dateComponents([.hour,.minute], from: startTime)
        let e = cal.dateComponents([.hour,.minute], from: endTime)
        guard let sh=s.hour, let sm=s.minute, let eh=e.hour, let em=e.minute else { return }
        var sr = Double(sh*60+sm - baseOffset); if sr < 0 { sr += 1440 }
        var er = Double(eh*60+em - baseOffset); if er < 0 { er += 1440 }
        sr = sr.truncatingRemainder(dividingBy: scale.totalMinutes)
        er = er.truncatingRemainder(dividingBy: scale.totalMinutes)
        startAngle = sr / scale.totalMinutes * 360
        endAngle   = er / scale.totalMinutes * 360
        previousEndAngle = endAngle
    }
    
    // MARK: ──────────────────────── 工具 ────────────────────────
    
    private func durationMinutes() -> Double {
        var d = endAngle - startAngle; if d <= 0 { d += 360 }
        return (d + Double(extraLaps) * 360) / 360 * scale.totalMinutes
    }
    private func inArc(_ a: Double) -> Bool {
        startAngle <= endAngle ? (a >= startAngle && a <= endAngle) : (a >= startAngle || a <= endAngle)
    }
    private func adiff(_ a: Double, _ b: Double) -> Double {
        (a - b + 180).truncatingRemainder(dividingBy: 360) - 180
    }
    private func fmtTime(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: d)
    }
}

private struct LabelItem: Hashable { let angle: Double; let text: String }

// MARK: - 预览

#Preview("1小时模式") {
    struct W: View {
        @State var s = Calendar.current.date(bySettingHour: 10, minute: 15, second: 0, of: Date())!
        @State var e = Calendar.current.date(bySettingHour: 10, minute: 45, second: 0, of: Date())!
        var body: some View {
            CircularTimeSlider(startTime: $s, endTime: $e, scale: .hour1, baseOffset: 600)
                .frame(width: 320, height: 320).padding()
        }
    }
    return W()
}

#Preview("24小时模式") {
    struct W: View {
        @State var s = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date())!
        @State var e = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!
        var body: some View {
            CircularTimeSlider(startTime: $s, endTime: $e, scale: .hour24, baseOffset: 0)
                .frame(width: 320, height: 320).padding()
        }
    }
    return W()
}
