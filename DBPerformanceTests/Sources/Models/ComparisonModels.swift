//
//  ComparisonModels.swift
//  DBPerformanceTests
//
//  결과 비교 UI 전용 데이터 모델
//  [CR-10] Sources/Models: 테스트 데이터 모델 및 비교 UI 모델
//

import Foundation
import SwiftUI

// MARK: - Scenario Enum

/// 검색 시나리오 타입
/// [TM-08~11] 4가지 검색 시나리오
enum Scenario: String, CaseIterable, Sendable {
    case equality = "Equality"
    case range = "Range"
    case complex = "Complex"
    case fullText = "FullText"

    var displayName: String {
        switch self {
        case .equality: return "Equality Search"
        case .range: return "Range Search"
        case .complex: return "Complex Search"
        case .fullText: return "Full-Text Search"
        }
    }
}

// MARK: - Search Benchmark File

/// 검색 벤치마크 파일 정보
/// [CR-46] 파일 선택: Results 디렉토리에서 *-search.json 파일만 필터링
struct SearchBenchmarkFile: Identifiable, Sendable {
    let id = UUID()
    let url: URL
    let filename: String
    let timestamp: Date
    let databaseName: String
}

// MARK: - Chart Data Point

/// 차트 렌더링용 데이터 포인트
/// [CR-48] 차트: SwiftUI Charts 사용, BarMark로 시나리오별 비교
struct ChartDataPoint: Identifiable, Sendable {
    let id = UUID()
    let database: String
    let scenario: Scenario
    let responseTimeMs: Double
    let resultCount: Int
}

// MARK: - Ranking Entry

/// 순위 테이블용 엔트리
/// [CR-50] 순위 표시: 시나리오별 Top 3 표시
struct RankingEntry: Sendable {
    let rank: Int
    let database: String
    let responseTimeMs: Double
    let resultCount: Int
}

// MARK: - Comparison Data

/// 선택된 파일들의 통합 비교 데이터
/// [TM-36] 비교 대상: SearchBenchmarkReport (검색 벤치마크 결과만)
struct ComparisonData: Sendable {
    let reports: [SearchBenchmarkReport]

    /// 특정 시나리오의 차트 데이터 반환
    /// [TM-39] 시나리오별 비교: 4가지 시나리오 각각 응답시간 비교
    func chartData(for scenario: Scenario) -> [ChartDataPoint] {
        reports.compactMap { report in
            guard let result = report.searchResults.first(where: { $0.scenario == scenario.rawValue }) else {
                return nil
            }
            return ChartDataPoint(
                database: report.metadata.databaseName,
                scenario: scenario,
                responseTimeMs: result.responseTimeMs,
                resultCount: result.resultCount
            )
        }
    }

    /// 시나리오별 순위 계산
    /// [TM-40] 순위 계산: 각 시나리오별 응답시간 기준 오름차순 정렬
    func rankings(for scenario: Scenario) -> [RankingEntry] {
        chartData(for: scenario)
            .sorted { $0.responseTimeMs < $1.responseTimeMs }
            .enumerated()
            .map { index, point in
                RankingEntry(
                    rank: index + 1,
                    database: point.database,
                    responseTimeMs: point.responseTimeMs,
                    resultCount: point.resultCount
                )
            }
    }
}

// MARK: - Database Color

/// DB별 색상 매핑
/// [CR-49] DB별 색상: Realm(Blue), CoreData(Green), SwiftData(Orange), UserDefaults(Purple)
enum DatabaseColor {
    static func color(for database: String) -> Color {
        switch database {
        case "Realm": return .blue
        case "CoreData": return .green
        case "SwiftData": return .orange
        case "UserDefaults": return .purple
        default: return .gray
        }
    }
}
