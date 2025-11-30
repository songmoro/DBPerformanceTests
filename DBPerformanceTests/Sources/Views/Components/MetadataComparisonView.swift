//
//  MetadataComparisonView.swift
//  DBPerformanceTests
//
//  메타데이터 비교 테이블 컴포넌트
//  [CR-51] 메타데이터 비교: Grid 레이아웃으로 환경 정보 테이블 표시
//

import SwiftUI

/// 메타데이터 비교 View
/// [TM-41] 환경 정보 비교: 테스트 일시, CPU, 메모리, macOS 버전 등 메타데이터 비교
struct MetadataComparisonView: View {
    let comparisonData: ComparisonData

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Environment Comparison")
                .font(.title2)
                .bold()

            ScrollView(.horizontal, showsIndicators: true) {
                Grid(alignment: .leading, horizontalSpacing: 25, verticalSpacing: 12) {
                    // Header Row
                    GridRow {
                        Text("Property")
                            .font(.headline)
                            .frame(width: 150, alignment: .leading)

                        ForEach(comparisonData.reports, id: \.metadata.timestamp) { report in
                            Text(report.metadata.databaseName)
                                .font(.headline)
                                .frame(width: 180, alignment: .leading)
                        }
                    }

                    Divider()

                    // Data Rows
                    metadataRow("Timestamp") { report in
                        formatTimestamp(report.metadata.timestamp)
                    }

                    metadataRow("Database Version") { report in
                        report.metadata.databaseVersion
                    }

                    metadataRow("Fixture Load Time") { report in
                        String(format: "%.2f ms", report.fixtureLoadTimeMs)
                    }

                    Divider()

                    metadataRow("CPU Model") { report in
                        shortCPUName(report.metadata.environment.cpuModel)
                    }

                    metadataRow("CPU Cores") { report in
                        "\(report.metadata.environment.cpuCores)"
                    }

                    metadataRow("RAM") { report in
                        String(format: "%.2f GB", report.metadata.environment.ramSize)
                    }

                    metadataRow("macOS Version") { report in
                        report.metadata.environment.macOSVersion
                    }

                    metadataRow("Swift Version") { report in
                        report.metadata.environment.swiftVersion
                    }

                    Divider()

                    metadataRow("CPU Usage") { report in
                        String(format: "%.1f%%", report.metadata.environment.cpuUsage)
                    }

                    metadataRow("Memory Usage") { report in
                        String(format: "%.1f%%", report.metadata.environment.memoryUsage)
                    }

                    metadataRow("Disk Usage") { report in
                        String(format: "%.1f%%", report.metadata.environment.diskUsage)
                    }
                }
            }
        }
        .padding()
    }

    // MARK: - Helper Methods

    @ViewBuilder
    private func metadataRow(_ label: String, value: @escaping (SearchBenchmarkReport) -> String) -> some View {
        GridRow {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 150, alignment: .leading)

            ForEach(comparisonData.reports, id: \.metadata.timestamp) { report in
                Text(value(report))
                    .font(.body)
                    .frame(width: 180, alignment: .leading)
            }
        }
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }

    private func shortCPUName(_ fullName: String) -> String {
        // "Apple M1 Pro" 형식으로 축약
        let components = fullName.split(separator: " ")
        if components.count >= 3 {
            return "\(components[0]) \(components[1]) \(components[2])"
        }
        return fullName
    }
}
