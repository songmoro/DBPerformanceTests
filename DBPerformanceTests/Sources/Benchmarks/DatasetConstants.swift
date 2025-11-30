//
//  DatasetConstants.swift
//  DBPerformanceTests
//
//  Dataset 생성 상수 관리
//  [CR-70~74] Search Test Configuration 중앙 관리
//

import Foundation

/// Constants derived from FixtureGenerator configuration
/// These values match the actual data generation logic
///
/// 모든 검색 테스트는 이 상수를 참조하여 실제 생성된 데이터와 일치하는 쿼리를 실행
enum DatasetConstants {

    // MARK: - Date Range Configuration

    /// Date range used in fixture generation
    /// FixtureGenerator.swift:36-37에서 사용되는 실제 날짜 범위
    static let dateRange = (
        start: Date(timeIntervalSince1970: 1672531200), // 2023-01-01 00:00:00 UTC
        end: Date(timeIntervalSince1970: 1735689600)     // 2024-12-31 00:00:00 UTC
    )

    // MARK: - Price Range Configuration

    /// Price range used in fixture generation
    /// 균등 분포로 생성되는 가격 범위
    static let priceRange = (
        min: 100,
        max: 50001  // exclusive upper bound (100..<50001)
    )

    // MARK: - Zipf Distribution Parameters

    /// Name field Zipf parameters
    /// ZipfianGenerator.nameGenerator에서 사용되는 파라미터
    static let nameDistribution = (
        skewness: 1.3,
        uniqueCount: 100
    )

    /// Category field Zipf parameters
    /// ZipfianGenerator.categoryGenerator에서 사용되는 파라미터
    static let categoryDistribution = (
        skewness: 1.5,
        uniqueCount: 50
    )

    // MARK: - Tag Configuration

    /// Tag cardinality per product (for relational models)
    /// 각 상품이 가지는 태그 개수 범위
    static let tagCardinality = (
        min: 1,
        max: 6,  // exclusive (1..<6, so 1-5 tags)
        average: 2.5
    )

    /// Total unique tag count
    /// ValueGenerators.tagNames 배열의 크기
    static let uniqueTagCount = 200

    // MARK: - Description Configuration

    /// Description length distribution
    /// FixtureGenerator.generateDescription()에서 사용되는 길이 분포
    /// [TM-32] 참조
    static let descriptionLengths: [(probability: Double, range: ClosedRange<Int>)] = [
        (0.3, 50...200),    // 30%: short descriptions
        (0.4, 200...500),   // 40%: medium descriptions
        (0.3, 500...2000)   // 30%: long descriptions
    ]

    // MARK: - Boolean Field Configuration

    /// isActive field probability
    /// true 값이 나올 확률
    static let isActiveProbability = 0.7  // 70% true, 30% false

    // MARK: - Seed Configuration

    /// Random seed for fixture generation (from FixtureGenerator)
    /// 재현 가능한 데이터 생성을 위한 시드값
    static let defaultSeed: UInt64 = 42

    // MARK: - Helper Methods

    /// Format date for query condition display
    /// - Parameter date: 포맷팅할 날짜
    /// - Returns: "yyyy-MM-dd" 형식의 문자열
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }

    /// Get description of all dataset constants
    /// - Returns: 모든 설정값을 포함한 설명 문자열
    static var description: String {
        """
        Dataset Configuration:
        - Date Range: \(formatDate(dateRange.start)) to \(formatDate(dateRange.end))
        - Price Range: \(priceRange.min) to \(priceRange.max - 1)
        - Name Distribution: Zipf(s=\(nameDistribution.skewness), k=\(nameDistribution.uniqueCount))
        - Category Distribution: Zipf(s=\(categoryDistribution.skewness), k=\(categoryDistribution.uniqueCount))
        - Tag Cardinality: \(tagCardinality.min)-\(tagCardinality.max - 1) per product (avg: \(tagCardinality.average))
        - Unique Tag Count: \(uniqueTagCount)
        - isActive Probability: \(isActiveProbability * 100)% true
        - Random Seed: \(defaultSeed)
        """
    }
}
