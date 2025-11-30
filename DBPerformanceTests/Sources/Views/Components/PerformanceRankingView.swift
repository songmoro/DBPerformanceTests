//
//  PerformanceRankingView.swift
//  DBPerformanceTests
//
//  성능 순위 표시 컴포넌트
//  [CR-50] 순위 표시: 시나리오별 Top 3 표시 (1st 금, 2nd 은, 3rd 동)
//

import SwiftUI

/// 성능 순위 View
/// [TM-40] 순위 계산: 각 시나리오별 응답시간 기준 오름차순 정렬
struct PerformanceRankingView: View {
    let comparisonData: ComparisonData

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Performance Rankings")
                .font(.title2)
                .bold()

            ForEach(Scenario.allCases, id: \.self) { scenario in
                VStack(alignment: .leading, spacing: 8) {
                    Text(scenario.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    let rankings = comparisonData.rankings(for: scenario)

                    if rankings.isEmpty {
                        Text("No data available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        HStack(spacing: 30) {
                            ForEach(rankings.prefix(3), id: \.database) { entry in
                                VStack(spacing: 4) {
                                    Text(rankSuffix(entry.rank))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(rankColor(entry.rank))

                                    Circle()
                                        .fill(DatabaseColor.color(for: entry.database))
                                        .frame(width: 12, height: 12)

                                    Text(entry.database)
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    Text(String(format: "%.2f ms", entry.responseTimeMs))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(width: 100)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)

                Divider()
            }
        }
        .padding()
    }

    // MARK: - Helper Methods

    private func rankSuffix(_ rank: Int) -> String {
        switch rank {
        case 1: return "1st"
        case 2: return "2nd"
        case 3: return "3rd"
        default: return "\(rank)th"
        }
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .brown
        default: return .secondary
        }
    }
}
