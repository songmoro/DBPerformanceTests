//
//  FlatModel.swift
//  DBPerformanceTests
//
//  검색 성능 측정용 단순 모델
//  [CR-34] FlatModel 필드 정의: id, name(Indexed), category(Indexed), price, date, description, isActive
//

import Foundation

/// 검색 최적화된 단순 모델
/// - 단일 테이블 구조
/// - Zipf 분포 적용 (name, category)
/// - 인덱스 필드: name, category
struct FlatModel: Codable, Equatable, Sendable {
    /// Primary Key - 고유 식별자
    let id: String

    /// 상품명 (Indexed)
    /// - Zipf 분포: s=1.3, k=100
    /// - 100가지 고유값 ("Product-A" ~ "Product-CV")
    /// - 최빈값: ~15K회 (1.5%), 최저: ~800회 (0.08%)
    let name: String

    /// 카테고리 (Indexed)
    /// - Zipf 분포: s=1.5, k=50
    /// - 50가지 고유값 ("Electronics", "Books", "Home", ...)
    /// - 최빈값: ~40K회 (4%), 최저: ~400회 (0.04%)
    let category: String

    /// 가격 (Non-Indexed, Range 검색용)
    /// - 균등 분포: 100 ~ 50000
    let price: Int

    /// 날짜 (Non-Indexed, Range/Complex 검색용)
    /// - 균등 분포: 2023-01-01 ~ 2024-12-31
    let date: Date

    /// 상세 설명 (Full-Text 검색용)
    /// - 혼합 길이:
    ///   - 30%: 50~200자 (짧은 설명)
    ///   - 40%: 200~500자 (중간 설명)
    ///   - 30%: 500~2000자 (긴 상세 설명)
    let description: String

    /// 활성 상태 (필터링용)
    /// - 70% true, 30% false
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, category, price, date, description, isActive
    }
}

// MARK: - Fixture Support

/// Fixture 파일 메타데이터
struct FixtureMetadata: Codable {
    let totalRecords: Int
    let generatedAt: String
    let datasetVersion: String
    let distribution: DistributionInfo?

    struct DistributionInfo: Codable {
        let name: String
        let category: String
    }
}

/// Fixture 파일 래퍼
struct FixtureWrapper: Codable {
    let metadata: FixtureMetadata
    let records: [FlatModel]
}

// MARK: - Fixture Loader

/// Fixture 파일 로더
/// [TM-30] Fixture 파일 포맷: JSON (메타데이터 + 레코드 배열)
struct FixtureLoader {
    /// Fixture 파일에서 FlatModel 로드
    /// - Parameter filePath: JSON 파일 경로
    /// - Returns: FlatModel 배열
    /// - Throws: 파일 읽기 또는 파싱 오류
    static func loadFlat(from filePath: String) async throws -> [FlatModel] {
        let url = URL(fileURLWithPath: filePath)
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let wrapper = try decoder.decode(FixtureWrapper.self, from: data)

        // [TM-35] 로딩 후 데이터 검증
        guard wrapper.records.count == wrapper.metadata.totalRecords else {
            throw FixtureError.recordCountMismatch(
                expected: wrapper.metadata.totalRecords,
                actual: wrapper.records.count
            )
        }

        return wrapper.records
    }
}

// MARK: - Errors

enum FixtureError: Error, CustomStringConvertible {
    case recordCountMismatch(expected: Int, actual: Int)

    var description: String {
        switch self {
        case .recordCountMismatch(let expected, let actual):
            return "Record count mismatch: expected \(expected), but got \(actual)"
        }
    }
}
