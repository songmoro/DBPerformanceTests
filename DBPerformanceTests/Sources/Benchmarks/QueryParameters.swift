//
//  QueryParameters.swift
//  DBPerformanceTests
//
//  검색 쿼리 파라미터 타입 안전 구조체
//  [CR-72] 기대 결과 개수 검증 지원
//

import Foundation

/// Type-safe query parameters for search scenarios
/// 각 검색 시나리오에 필요한 파라미터만 설정 (나머지는 nil)
struct QueryParameters: Sendable {

    // MARK: - Flat Model Search Parameters

    /// Name field exact match value
    /// Equality Search에서 사용
    let name: String?

    /// Category field exact match value
    /// Complex Search에서 사용
    let category: String?

    /// Minimum price for range queries
    /// Range Search, Complex Search에서 사용
    let priceMin: Int?

    /// Maximum price for range queries
    /// Range Search, Complex Search에서 사용
    let priceMax: Int?

    /// Date filter start point
    /// Complex Search에서 사용 (date >= dateFrom)
    let dateFrom: Date?

    /// Keyword for full-text search in description field
    /// Full-Text Search에서 사용
    let keyword: String?

    // MARK: - Relational Model Search Parameters

    /// Single tag name for tag-based queries
    /// Tag Equality, Range+Tag, Complex+Tag, FullText+Tag에서 사용
    let tag: String?

    /// Multiple tag names for AND logic queries
    /// Multiple Tags Search에서 사용
    let tags: [String]?

    // MARK: - Result Validation

    /// Expected result count for validation
    /// 실제 검색 결과 개수가 이 범위에 있는지 검증
    let expectedCount: ExpectedCount

    // MARK: - Initializer

    /// Initialize query parameters
    /// - Parameters:
    ///   - name: Product name for equality search
    ///   - category: Category for filtering
    ///   - priceMin: Minimum price (inclusive)
    ///   - priceMax: Maximum price (inclusive)
    ///   - dateFrom: Date filter (>= dateFrom)
    ///   - keyword: Full-text search keyword
    ///   - tag: Single tag name
    ///   - tags: Multiple tag names (AND logic)
    ///   - expectedCount: Expected result count range
    init(
        name: String? = nil,
        category: String? = nil,
        priceMin: Int? = nil,
        priceMax: Int? = nil,
        dateFrom: Date? = nil,
        keyword: String? = nil,
        tag: String? = nil,
        tags: [String]? = nil,
        expectedCount: ExpectedCount
    ) {
        self.name = name
        self.category = category
        self.priceMin = priceMin
        self.priceMax = priceMax
        self.dateFrom = dateFrom
        self.keyword = keyword
        self.tag = tag
        self.tags = tags
        self.expectedCount = expectedCount
    }
}

// MARK: - Expected Count

/// Expected result count for validation
/// 검색 결과 개수 검증을 위한 기대값 정의
enum ExpectedCount: Sendable {

    /// Exact count expected
    /// 정확히 N개의 결과 예상
    case exact(Int)

    /// Range of acceptable counts
    /// min ~ max 범위 내 결과 예상
    case range(min: Int, max: Int)

    /// Any count is acceptable (no validation)
    /// 개수 검증 불필요 (실험적 쿼리 등에 사용)
    case any

    // MARK: - Validation

    /// Validate actual result count against expected
    /// - Parameter actual: 실제 검색 결과 개수
    /// - Returns: 검증 통과 여부
    func validate(_ actual: Int) -> Bool {
        switch self {
        case .exact(let expected):
            return actual == expected

        case .range(let min, let max):
            return actual >= min && actual <= max

        case .any:
            return true
        }
    }

    // MARK: - Description

    /// Human-readable description of expected count
    var description: String {
        switch self {
        case .exact(let count):
            return "exactly \(count)"

        case .range(let min, let max):
            return "\(min)-\(max)"

        case .any:
            return "any"
        }
    }
}
