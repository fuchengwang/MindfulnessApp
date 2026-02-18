//
//  MindfulnessWidgetBundle.swift
//  MindfulnessWidget
//
//  Created by 富诚 on 2026/2/9.
//

import WidgetKit
import SwiftUI

@main
struct MindfulnessWidgetBundle: WidgetBundle {
    var body: some Widget {
        MindfulnessWidget()
        WeeklyTrendWidget()
        // MindfulnessWidgetControl() // ControlWidget is iOS 18+ only
    }
}
