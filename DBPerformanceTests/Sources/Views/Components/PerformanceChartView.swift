//
//  PerformanceChartView.swift
//  DBPerformanceTests
//
//  성능 비교 차트 컴포넌트
//  [CR-48] 차트: SwiftUI Charts 사용, BarMark로 시나리오별 비교
//

import SwiftUI
import Charts

/// 성능 비교 차트 View
/// [TM-39] 시나리오별 비교: 4가지 시나리오 각각 응답시간 비교
struct PerformanceChartView: View {
    let comparisonData: ComparisonData

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Performance Comparison")
                .font(.title2)
                .bold()

            ForEach(Scenario.allCases, id: \.self) { scenario in
                VStack(alignment: .leading, spacing: 10) {
                    Text(scenario.displayName)
                        .font(.headline)

                    let chartData = comparisonData.chartData(for: scenario)

                    if chartData.isEmpty {
                        Text("No data available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(height: 180)
                    } else {
                        Chart {
                            ForEach(chartData, id: \.id) { dataPoint in
                                BarMark(
                                    x: .value("Database", dataPoint.database),
                                    y: .value("Response Time (ms)", dataPoint.responseTimeMs)
                                )
                                .foregroundStyle(DatabaseColor.color(for: dataPoint.database))
                                .annotation(position: .top) {
                                    Text(String(format: "%.1f", dataPoint.responseTimeMs))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .frame(height: 180)
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisValueLabel {
                                    if let ms = value.as(Double.self) {
                                        Text(String(format: "%.0f ms", ms))
                                    }
                                }
                            }
                        }
                        .chartXAxis {
                            AxisMarks { value in
                                AxisValueLabel {
                                    Text(value.as(String.self) ?? "")
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 10)

                Divider()
            }
        }
        .padding()
    }
}
