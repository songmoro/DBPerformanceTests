//
//  SearchBenchmark.swift
//  DBPerformanceTests
//
//  검색 벤치마크 시간 측정
//  [CR-42] 시간 측정: ContinuousClock 사용하여 응답 시간(ms) 측정
//

import Foundation

/// 검색 벤치마크 측정 유틸리티
struct SearchBenchmark {
    private let clock = ContinuousClock()

    /// 검색 작업 시간 측정 및 SearchResult 반환
    /// - Parameter operation: 검색 작업 클로저
    /// - Returns: responseTimeMs가 포함된 SearchResult
    func measure(_ operation: () throws -> SearchResult) rethrows -> SearchResult {
        var result: SearchResult!

        let duration = clock.measure {
            result = try! operation()
        }

        let milliseconds = Double(duration.components.seconds) * 1000.0 +
                          Double(duration.components.attoseconds) / 1_000_000_000_000_000.0

        return SearchResult(
            results: result.results,
            count: result.count,
            responseTimeMs: milliseconds
        )
    }

    /// 비동기 검색 작업 시간 측정
    /// - Parameter operation: 비동기 검색 작업 클로저
    /// - Returns: responseTimeMs가 포함된 SearchResult
    func measureAsync(_ operation: () async throws -> SearchResult) async rethrows -> SearchResult {
        var result: SearchResult!

        let duration = try await clock.measure {
            result = try await operation()
        }

        let milliseconds = Double(duration.components.seconds) * 1000.0 +
                          Double(duration.components.attoseconds) / 1_000_000_000_000_000.0

        return SearchResult(
            results: result.results,
            count: result.count,
            responseTimeMs: milliseconds
        )
    }

    /// SearchResult를 SearchBenchmarkResult로 변환
    /// - Parameters:
    ///   - searchResult: 검색 결과
    ///   - scenario: 시나리오 이름 ("Equality", "Range", "Complex", "FullText")
    ///   - indexed: 인덱스 사용 여부
    ///   - queryCondition: 쿼리 조건 설명 (선택)
    /// - Returns: SearchBenchmarkResult
    static func toBenchmarkResult(
        _ searchResult: SearchResult,
        scenario: String,
        indexed: Bool,
        queryCondition: String? = nil
    ) -> SearchBenchmarkResult {
        SearchBenchmarkResult(
            scenario: scenario,
            responseTimeMs: searchResult.responseTimeMs ?? 0,
            resultCount: searchResult.count,
            indexed: indexed,
            queryCondition: queryCondition
        )
    }
}
