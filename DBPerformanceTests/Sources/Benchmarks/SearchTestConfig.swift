//
//  SearchTestConfig.swift
//  DBPerformanceTests
//
//  검색 테스트 시나리오 설정
//  [CR-70] 검색 테스트 쿼리 파라미터 중앙 관리
//  [CR-71] 실제 데이터 분포(Zipf, uniform)를 고려한 값 사용
//  [CR-73] 하드코딩된 쿼리 값 금지
//

import Foundation

/// Central configuration for all search test scenarios
/// 모든 검색 시나리오의 쿼리 파라미터와 기대값을 중앙에서 관리
///
/// **사용 예시:**
/// ```swift
/// let config = SearchTestConfig.equalitySearch
/// let params = config.queryParams
/// let result = try searcher.searchByName(params.name!)
/// if !params.expectedCount.validate(result.count) {
///     print("⚠️ Warning: \(config) returned \(result.count), expected \(params.expectedCount)")
/// }
/// ```
enum SearchTestConfig: CustomStringConvertible, CaseIterable {

    // MARK: - Flat Model Search Scenarios

    /// [TM-08] Equality Search Configuration
    /// name 필드 정확 일치 검색
    case equalitySearch

    /// [TM-09] Range Search Configuration
    /// price 범위 검색
    case rangeSearch

    /// [TM-10] Complex Search Configuration
    /// category + price + date 복합 조건 검색
    case complexSearch

    /// [TM-11] Full-Text Search Configuration
    /// description 필드 텍스트 검색
    case fullTextSearch

    // MARK: - Relational Model Search Scenarios

    /// [TM-38a] Tag Equality Search Configuration
    /// 특정 tag를 가진 ProductRecord 검색
    case tagEqualitySearch

    /// [TM-38b] Range + Tag Search Configuration
    /// price 범위 + tag 조합 검색
    case rangeTagSearch

    /// [TM-38c] Complex + Tag Search Configuration
    /// category + price + date + tag 복합 검색
    case complexTagSearch

    /// [TM-38d] Full-Text + Tag Search Configuration
    /// description 텍스트 + tag 조합 검색
    case fullTextTagSearch

    /// [TM-38e] Multiple Tags Search Configuration
    /// 여러 tag를 동시에 가진 ProductRecord 검색 (AND 로직)
    case multipleTagsSearch

    // MARK: - Configuration Access

    /// Get query parameters for this scenario
    /// 각 시나리오에 맞는 쿼리 파라미터 반환
    var queryParams: QueryParameters {
        switch self {

        // MARK: Flat Scenarios

        case .equalitySearch:
            // 가장 빈번하게 나타나는 상품명으로 검색
            // Zipf rank 1 = "Product-AA"
            // 1M 레코드에서 ~15,000개 (1.5%) 예상
            return .init(
                name: ValueGenerators.mostFrequentName,
                expectedCount: .range(min: 13000, max: 17000)
            )

        case .rangeSearch:
            // price 범위 1000-5000
            // 전체 범위 100-50000 중 약 8% 커버
            // 1M 레코드에서 ~80,000개 예상
            return .init(
                priceMin: 1000,
                priceMax: 5000,
                expectedCount: .range(min: 75000, max: 85000)
            )

        case .complexSearch:
            // category="Electronics" (가장 빈번, Zipf rank 1)
            // + price 범위 2000-8000
            // + date >= 2023-01-01 (전체 범위와 일치)
            // 1M 레코드에서 ~8,000-12,000개 예상
            return .init(
                category: ValueGenerators.mostFrequentCategory,
                priceMin: 2000,
                priceMax: 8000,
                dateFrom: DatasetConstants.dateRange.start,
                expectedCount: .range(min: 6000, max: 14000)
            )

        case .fullTextSearch:
            // description에 "premium" 키워드 포함
            // DescriptionWords에 "premium"이 포함됨
            // 1M 레코드에서 ~15,000-25,000개 예상 (~2%)
            return .init(
                keyword: "premium",
                expectedCount: .range(min: 12000, max: 28000)
            )

        // MARK: Relational Scenarios

        case .tagEqualitySearch:
            // tag name = "new-tech" (첫 번째 생성된 태그)
            // 1M 레코드, 평균 2.5 tags/product
            // tag 선택 확률 1/200, ~0.5%
            // 1M 레코드에서 ~4,000-6,000개 예상
            return .init(
                tag: ValueGenerators.tagByIndex(0), // "new-tech"
                expectedCount: .range(min: 3000, max: 7000)
            )

        case .rangeTagSearch:
            // price 범위 1000-5000 (~8%)
            // + tag "sale-value" (10번째 태그)
            // 두 조건 교집합: ~3,000-5,000개 예상
            return .init(
                priceMin: 1000,
                priceMax: 5000,
                tag: ValueGenerators.tagByIndex(10), // "sale-value"
                expectedCount: .range(min: 2500, max: 6000)
            )

        case .complexTagSearch:
            // category="Electronics" (~4%)
            // + price 범위 2000-8000
            // + date >= 2023-01-01
            // + tag "hot-deal" (20번째 태그)
            // 복합 조건 교집합: ~500-2,000개 예상
            return .init(
                category: ValueGenerators.mostFrequentCategory,
                priceMin: 2000,
                priceMax: 8000,
                dateFrom: DatasetConstants.dateRange.start,
                tag: ValueGenerators.tagByIndex(20), // "hot-deal"
                expectedCount: .range(min: 400, max: 2500)
            )

        case .fullTextTagSearch:
            // description에 "premium" 포함 (~2%)
            // + tag "premium-quality" (5번째 태그, ~0.5%)
            // 두 조건 교집합: ~800-1,500개 예상
            return .init(
                keyword: "premium",
                tag: ValueGenerators.tagByIndex(5), // "premium-quality"
                expectedCount: .range(min: 600, max: 2000)
            )

        case .multipleTagsSearch:
            // tag "premium-value" AND tag "hot-deal"
            // 두 태그를 모두 가진 제품만 (매우 선택적)
            // 1M 레코드에서 ~50-200개 예상
            return .init(
                tags: [
                    ValueGenerators.tagByIndex(15), // "premium-value"
                    ValueGenerators.tagByIndex(20)  // "hot-deal"
                ],
                expectedCount: .range(min: 30, max: 300)
            )
        }
    }

    // MARK: - Scenario Metadata

    /// Scenario description for reporting
    /// 결과 파일에 저장되는 시나리오 이름
    var description: String {
        switch self {
        case .equalitySearch:
            return "Equality"
        case .rangeSearch:
            return "Range"
        case .complexSearch:
            return "Complex"
        case .fullTextSearch:
            return "FullText"
        case .tagEqualitySearch:
            return "Relational-TagEquality"
        case .rangeTagSearch:
            return "Relational-RangeTag"
        case .complexTagSearch:
            return "Relational-ComplexTag"
        case .fullTextTagSearch:
            return "Relational-FullTextTag"
        case .multipleTagsSearch:
            return "Relational-MultipleTags"
        }
    }

    /// Human-readable query condition for reporting
    /// 검색 조건을 사람이 읽을 수 있는 형식으로 표현
    var queryCondition: String {
        let params = queryParams

        switch self {
        case .equalitySearch:
            return "name == '\(params.name!)'"

        case .rangeSearch:
            return "price BETWEEN \(params.priceMin!) AND \(params.priceMax!)"

        case .complexSearch:
            let dateStr = DatasetConstants.formatDate(params.dateFrom!)
            return "category='\(params.category!)' AND price BETWEEN \(params.priceMin!)-\(params.priceMax!) AND date>='\(dateStr)'"

        case .fullTextSearch:
            return "description CONTAINS '\(params.keyword!)'"

        case .tagEqualitySearch:
            return "tags CONTAINS '\(params.tag!)'"

        case .rangeTagSearch:
            return "price BETWEEN \(params.priceMin!)-\(params.priceMax!) AND tags CONTAINS '\(params.tag!)'"

        case .complexTagSearch:
            let dateStr = DatasetConstants.formatDate(params.dateFrom!)
            return "category='\(params.category!)' AND price BETWEEN \(params.priceMin!)-\(params.priceMax!) AND date>='\(dateStr)' AND tags CONTAINS '\(params.tag!)'"

        case .fullTextTagSearch:
            return "description CONTAINS '\(params.keyword!)' AND tags CONTAINS '\(params.tag!)'"

        case .multipleTagsSearch:
            let tagList = params.tags!.map { "'\($0)'" }.joined(separator: " AND tags CONTAINS ")
            return "tags CONTAINS \(tagList)"
        }
    }

    /// TM reference code
    /// 각 시나리오의 [TM-XX] 참조 코드
    var tmCode: String {
        switch self {
        case .equalitySearch:
            return "TM-08"
        case .rangeSearch:
            return "TM-09"
        case .complexSearch:
            return "TM-10"
        case .fullTextSearch:
            return "TM-11"
        case .tagEqualitySearch:
            return "TM-38a"
        case .rangeTagSearch:
            return "TM-38b"
        case .complexTagSearch:
            return "TM-38c"
        case .fullTextTagSearch:
            return "TM-38d"
        case .multipleTagsSearch:
            return "TM-38e"
        }
    }

    /// Whether this scenario requires relational model
    /// Relational 모델 필요 여부
    var isRelational: Bool {
        switch self {
        case .equalitySearch, .rangeSearch, .complexSearch, .fullTextSearch:
            return false
        case .tagEqualitySearch, .rangeTagSearch, .complexTagSearch, .fullTextTagSearch, .multipleTagsSearch:
            return true
        }
    }

    // MARK: - Scenario Groups

    /// All flat model scenarios
    static var flatScenarios: [SearchTestConfig] {
        [.equalitySearch, .rangeSearch, .complexSearch, .fullTextSearch]
    }

    /// All relational model scenarios
    static var relationalScenarios: [SearchTestConfig] {
        [.tagEqualitySearch, .rangeTagSearch, .complexTagSearch, .fullTextTagSearch, .multipleTagsSearch]
    }
}
