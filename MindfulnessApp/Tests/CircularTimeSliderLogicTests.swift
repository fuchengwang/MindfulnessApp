import Foundation

// MARK: - 逻辑测试用例 (Logic Test Cases)

class CircularTimeSliderLogicTests {
    
    // 模拟状态 (Mock State)
    var startAngle: Double = 0
    var endAngle: Double = 0
    var extraLaps: Int = 0
    var scaleMinutes: Double = 60 // 1小时一圈
    var allowMultiLap: Bool = true
    
    init() {
        print("🚀 开始 CircularTimeSlider 逻辑测试 (Starting Logic Tests)")
    }
    
    // 辅助函数：计算当前时长 (Helper: Calculate Duration)
    func currentDuration() -> Double {
        var d = endAngle - startAngle
        if allowMultiLap {
            if d < 0 { d += 360 } // [0, 360)
        } else {
            if d <= 0 { d += 360 } // (0, 360]
        }
        return (d + Double(extraLaps) * 360) / 360 * scaleMinutes
    }
    
    // 辅助函数：模拟拖动逻辑 (Helper: Simulate Drag Logic)
    // 简化版，只关注 updateExtraLaps 核心逻辑
    func updateExtraLaps(oldDiff: Double, newDiff: Double) {
        if oldDiff > 270 && newDiff < 90 {
            extraLaps += 1
            print("   -> 增加圈数 (Laps +1) = \(extraLaps)")
        } else if oldDiff < 90 && newDiff > 270 {
            if extraLaps > 0 { extraLaps -= 1 }
            print("   -> 减少圈数 (Laps -1) = \(extraLaps)")
        }
    }
    
    func runTests() {
        testCase1_StartCrossesEnd_CCW()
        testCase2_StartCrossesEnd_CW_Reverse()
        testCase3_EndCrossesStart_CW()
        testCase4_EndCrossesStart_CCW_Reverse()
        testCase5_ZeroDuration()
        print("✅ 所有测试完成 (All Tests Completed)\n")
    }
    
    // 用例 1: 起点 逆时针 跨过 终点 (增加时长)
    func testCase1_StartCrossesEnd_CCW() {
        print("\n🧪 测试用例 1: 起点逆时针跨越终点 (Start moves CCW past End)")
        reset()
        // 初始: Start=0, End=10 (1.67分). Laps=0. Diff=10.
        startAngle = 0; endAngle = 10
        let oldDiff = getDiff()
        
        // 动作: Start 逆时针移动到 350 (-10). 
        // 视觉上: Start 跨过了 End (10 -> 0 -> 350).
        // 实际上: Diff (End-Start) 从 10 变成了 10-350 = -340 -> 20.
        // 等等，Start 变 350. Diff = 10 - 350 = -340 -> +360 = 20.
        // Diff 变化: 10 -> 20. 没有跨越?
        
        // 让我们修正 Start 移动方向.
        // Start 逆时针 (0 -> 350 -> 340).
        // End 固定 10.
        // Start=0, End=10. Diff=10.
        // Start=350, End=10. Diff=20.
        // Start=10, End=10. Diff=0.
        
        // 如果 Start 跨越 End (增加时间):
        // Start 从 15 移动到 5 (跨过 10?).
        // Start=15, End=10. Diff (10-15+360) = 355.
        // Start=5, End=10. Diff = 5.
        // Diff 355 -> 5. 跨越了 0/360 边界.
        // oldDiff(355) > 270, newDiff(5) < 90.
        // Laps++ ?
        
        // 场景: Start=15, End=10.
        startAngle = 15; endAngle = 10
        print("   初始状态: Start=15, End=10, Diff=\(getDiff())") // 355
        
        let d1 = getDiff()
        startAngle = 5 // 移动到 5
        let d2 = getDiff() // 5
        
        print("   移动后: Start=5, End=10, Diff=\(d2)")
        updateExtraLaps(oldDiff: d1, newDiff: d2)
        
        assert(extraLaps == 1, "❌ 错误: 应该增加一圈 (Should have 1 lap)")
        print("   ✅ 结果正确: 圈数变为 1")
    }
    
    // 用例 2: 起点 顺时针 跨越 终点 (减少时长)
    func testCase2_StartCrossesEnd_CW_Reverse() {
        print("\n🧪 测试用例 2: 起点顺时针跨越终点 (Start moves CW past End)")
        reset()
        extraLaps = 1
        // 初始: Start=5, End=10. Diff=5. Laps=1. Duration = 60+0.83 = 60.83m.
        startAngle = 5; endAngle = 10
        print("   初始状态 (1圈): Start=5, End=10, Diff=\(getDiff())")
        
        let d1 = getDiff()
        // 顺时针移动 Start 到 15 (跨过 10).
        startAngle = 15
        let d2 = getDiff() // 355
        
        print("   移动后: Start=15, End=10, Diff=\(d2)")
        updateExtraLaps(oldDiff: d1, newDiff: d2) // 5 -> 355
        
        assert(extraLaps == 0, "❌ 错误: 应该减少一圈 (Should have 0 laps)")
        print("   ✅ 结果正确: 圈数变为 0")
    }
    
    // 用例 3: 终点 顺时针 跨越 起点 (增加时长)
    func testCase3_EndCrossesStart_CW() {
        print("\n🧪 测试用例 3: 终点顺时针跨越起点 (End moves CW past Start)")
        reset()
        // 初始: Start=10, End=5. Diff=355.
        startAngle = 10; endAngle = 5
        print("   初始状态: Start=10, End=5, Diff=\(getDiff())")
        
        let d1 = getDiff()
        // End 顺时针移动到 15 (跨过 10).
        endAngle = 15
        let d2 = getDiff() // 5
        
        print("   移动后: Start=10, End=15, Diff=\(d2)")
        updateExtraLaps(oldDiff: d1, newDiff: d2) // 355 -> 5
        
        assert(extraLaps == 1, "❌ 错误: 应该增加一圈 (Should have 1 lap)")
        print("   ✅ 结果正确: 圈数变为 1")
    }
    
    // 用例 4: 终点 逆时针 跨越 起点 (减少时长)
    func testCase4_EndCrossesStart_CCW_Reverse() {
        print("\n🧪 测试用例 4: 终点逆时针跨越起点 (End moves CCW past Start)")
        reset()
        extraLaps = 1
        // 初始: Start=10, End=15. Diff=5. Laps=1.
        startAngle = 10; endAngle = 15
        print("   初始状态 (1圈): Start=10, End=15, Diff=\(getDiff())")
        
        let d1 = getDiff()
        // End 逆时针移动到 5 (跨过 10).
        endAngle = 5
        let d2 = getDiff() // 355
        
        print("   移动后: Start=10, End=5, Diff=\(d2)")
        updateExtraLaps(oldDiff: d1, newDiff: d2) // 5 -> 355
        
        assert(extraLaps == 0, "❌ 错误: 应该减少一圈 (Should have 0 laps)")
        print("   ✅ 结果正确: 圈数变为 0")
    }
    
    // 用例 5: 0时长检查
    func testCase5_ZeroDuration() {
        print("\n🧪 测试用例 5: 零时长检查 (Zero Duration Check)")
        reset()
        startAngle = 0; endAngle = 0; extraLaps = 0
        let dur = currentDuration()
        print("   Start=0, End=0, Laps=0 -> Duration=\(dur)m")
        assert(dur == 0, "❌ 错误: 时长应为 0")
        
        extraLaps = 1
        let dur2 = currentDuration()
        print("   Start=0, End=0, Laps=1 -> Duration=\(dur2)m")
        assert(dur2 == 60, "❌ 错误: 时长应为 60")
        print("   ✅ 结果正确")
    }
    
    // Helpers
    func reset() { startAngle = 0; endAngle = 0; extraLaps = 0 }
    func getDiff() -> Double {
        var d = endAngle - startAngle
        if d < 0 { d += 360 }
        return d
    }
}

// 自动运行
// let tester = CircularTimeSliderLogicTests()
// tester.runTests()
