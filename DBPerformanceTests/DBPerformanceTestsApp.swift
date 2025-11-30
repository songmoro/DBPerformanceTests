//
//  DBPerformanceTestsApp.swift
//  DBPerformanceTests
//
//  Created by 송재훈 on 11/29/25.
//  [CR-44] TabView 구조: Benchmarks 탭 + Comparison 탭
//

import SwiftUI

@main
struct DBPerformanceTestsApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        Label("Benchmarks", systemImage: "chart.bar.fill")
                    }

                ResultsComparisonView()
                    .tabItem {
                        Label("Comparison", systemImage: "chart.line.uptrend.xyaxis")
                    }
            }
            .frame(minWidth: 1000, minHeight: 700)
        }
    }
}
