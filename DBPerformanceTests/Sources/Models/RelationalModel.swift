//
//  RelationalModel.swift
//  DBPerformanceTests
//
//  검색 성능 측정용 복합 모델 (1:N 관계)
//  [CR-35] RelationalModel: ProductRecord + Tag 1:N 관계
//

import Foundation

/// 1:N 관계를 포함한 상품 레코드
/// - ProductRecord 1개당 평균 2.5개 Tag
/// - 전체 태그 관계: 2.5M개 (1M * 2.5)
struct ProductRecord: Codable, Equatable, Sendable {
    /// Primary Key - 고유 식별자
    let id: String

    /// 상품명 (Indexed)
    /// - Zipf 분포: s=1.3, k=100
    let name: String

    /// 카테고리 (Indexed)
    /// - Zipf 분포: s=1.5, k=50
    let category: String

    /// 가격 (Non-Indexed, Range 검색용)
    /// - 균등 분포: 100 ~ 50000
    let price: Int

    /// 날짜 (Non-Indexed)
    /// - 균등 분포: 2023-01-01 ~ 2024-12-31
    let date: Date

    /// 상세 설명 (Full-Text 검색용)
    /// - 혼합 길이: 50~2000자
    let description: String

    /// 활성 상태
    /// - 70% true, 30% false
    let isActive: Bool

    /// 태그 목록 (1:N 관계)
    /// - 각 레코드당 1~5개 태그
    /// - 전체 200가지 고유 태그
    let tags: [String]

    enum CodingKeys: String, CodingKey {
        case id, name, category, price, date, description, isActive, tags
    }
}

/// 태그 엔티티 (관계형)
/// - ProductRecord와 1:N 관계
/// - 전체 200가지 고유 태그
struct Tag: Codable, Equatable, Sendable {
    /// Primary Key
    let id: String

    /// 태그명
    /// - 예: "electronics", "sale", "new", "premium", ...
    let tagName: String

    /// 생성 시각
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, tagName, createdAt
    }
}

// MARK: - Fixture Support

/// RelationalModel Fixture 래퍼
struct RelationalFixtureWrapper: Codable {
    let metadata: FixtureMetadata
    let products: [ProductRecord]
    let tags: [Tag]?  // Optional: 별도 관리 가능
}

/// RelationalModel Fixture 로더
struct RelationalFixtureLoader {
    /// Fixture 파일에서 ProductRecord 로드
    /// - Parameter filePath: JSON 파일 경로
    /// - Returns: ProductRecord 배열
    /// - Throws: 파일 읽기 또는 파싱 오류
    static func loadRelational(from filePath: String) async throws -> [ProductRecord] {
        let url = URL(fileURLWithPath: filePath)
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let wrapper = try decoder.decode(RelationalFixtureWrapper.self, from: data)

        // [TM-35] 로딩 후 데이터 검증
        guard wrapper.products.count == wrapper.metadata.totalRecords else {
            throw FixtureError.recordCountMismatch(
                expected: wrapper.metadata.totalRecords,
                actual: wrapper.products.count
            )
        }

        return wrapper.products
    }

    /// Tag 배열과 함께 로드
    /// - Parameter filePath: JSON 파일 경로
    /// - Returns: (ProductRecord 배열, Tag 배열)
    static func loadWithTags(from filePath: String) async throws -> ([ProductRecord], [Tag]) {
        let url = URL(fileURLWithPath: filePath)
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let wrapper = try decoder.decode(RelationalFixtureWrapper.self, from: data)

        guard wrapper.products.count == wrapper.metadata.totalRecords else {
            throw FixtureError.recordCountMismatch(
                expected: wrapper.metadata.totalRecords,
                actual: wrapper.products.count
            )
        }

        return (wrapper.products, wrapper.tags ?? [])
    }
}
