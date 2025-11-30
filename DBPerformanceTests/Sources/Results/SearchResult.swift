//
//  SearchResult.swift
//  DBPerformanceTests
//
//  검색 결과 구조체
//  [CR-41] 검색 결과 반환: SearchResult(results, count, responseTimeMs)
//

import Foundation

/// 검색 결과 (제네릭)
struct SearchResult<T: Sendable>: Sendable {
    /// 검색된 레코드 배열
    let results: [T]

    /// 결과 개수
    let count: Int

    /// 응답 시간 (밀리초)
    let responseTimeMs: Double?

    init(results: [T], count: Int, responseTimeMs: Double? = nil) {
        self.results = results
        self.count = count
        self.responseTimeMs = responseTimeMs
    }
}

/// 검색 벤치마크 결과
struct SearchBenchmarkResult: Codable, Sendable {
    /// 시나리오 이름
    let scenario: String  // "Equality", "Range", "Complex", "FullText"

    /// 응답 시간 (밀리초)
    let responseTimeMs: Double

    /// 결과 개수
    let resultCount: Int

    /// 인덱스 사용 여부
    let indexed: Bool

    /// 쿼리 조건 (선택)
    let queryCondition: String?

    init(
        scenario: String,
        responseTimeMs: Double,
        resultCount: Int,
        indexed: Bool,
        queryCondition: String? = nil
    ) {
        self.scenario = scenario
        self.responseTimeMs = responseTimeMs
        self.resultCount = resultCount
        self.indexed = indexed
        self.queryCondition = queryCondition
    }
}

/// 인덱스 비교 결과
struct IndexComparisonResult: Codable, Sendable {
    /// 필드명
    let field: String

    /// 인덱스 적용 시 응답 시간 (ms)
    let indexedTimeMs: Double

    /// 인덱스 미적용 시 응답 시간 (ms)
    let nonIndexedTimeMs: Double

    /// 효율성 배수 (nonIndexed / indexed)
    var efficiency: Double {
        guard indexedTimeMs > 0 else { return 0 }
        return nonIndexedTimeMs / indexedTimeMs
    }

    /// 결과 개수
    let resultCount: Int
}

/// 결과 개수별 성능 메트릭
struct ResultCountMetric: Codable, Sendable {
    /// 목표 결과 개수
    let targetCount: Int

    /// 실제 결과 개수
    let actualCount: Int

    /// 응답 시간 (ms)
    let responseTimeMs: Double

    /// 쿼리 조건
    let queryCondition: String
}
