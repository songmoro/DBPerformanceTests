//
//  RealmRelationalSearcher.swift
//  DBPerformanceTests
//
//  Realm 관계형 검색 구현 (1:N - ProductRecord + Tags)
//  [CR-40] 구체 타입 사용: 프로토콜 제거, DB별 독립 Searcher 클래스
//

import Foundation
@preconcurrency import RealmSwift

/// Realm 관계형 검색 구현 클래스
/// - ProductRecord와 Tag 1:N 관계
/// - 5가지 관계형 검색 시나리오 지원
@MainActor
final class RealmRelationalSearcher {
    private var realm: Realm?
    private let dbPath: String

    init(dbPath: String = "relational_search_test.realm") {
        self.dbPath = dbPath
    }

    // MARK: - Initialization

    /// DB 초기화
    func initializeDB() throws {
        let config = Realm.Configuration(
            fileURL: URL(fileURLWithPath: dbPath),
            schemaVersion: 1,
            deleteRealmIfMigrationNeeded: true
        )
        self.realm = try Realm(configuration: config)
    }

    /// Fixture에서 데이터 로드
    func loadFromFixture(path: String) async throws -> Duration {
        let models = try await RelationalFixtureLoader.loadRelational(from: path)

        let clock = ContinuousClock()
        let duration = try clock.measure {
            guard let realm = self.realm else {
                throw RealmRelationalSearcherError.notInitialized
            }

            try realm.write {
                realm.deleteAll()

                for model in models {
                    realm.add(RealmProductRecord(from: model))
                }
            }
        }

        let count = realm?.objects(RealmProductRecord.self).count ?? 0
        guard count == models.count else {
            throw RealmRelationalSearcherError.dataVerificationFailed(
                expected: models.count,
                actual: count
            )
        }

        return duration
    }

    // MARK: - Search Methods

    /// Relational-01: Tag Equality Search (특정 태그 검색)
    /// - Parameters:
    ///   - tag: 검색할 태그명
    ///   - indexed: 인덱스 사용 여부
    /// - Returns: 검색 결과
    func searchByTag(_ tag: String, indexed: Bool = true) throws -> SearchResult<ProductRecord> {
        guard let realm = self.realm else {
            throw RealmRelationalSearcherError.notInitialized
        }

        let results = realm.objects(RealmProductRecord.self)
            .where { $0.tags.contains(tag) }
            .freeze()

        let models = Array(results.map { $0.toProductRecord() })
        return SearchResult(results: models, count: models.count)
    }

    /// Relational-02: Range + Tag Search (가격 범위 + 태그)
    /// - Parameters:
    ///   - priceMin: 최소 가격
    ///   - priceMax: 최대 가격
    ///   - tag: 필터링할 태그
    /// - Returns: 검색 결과
    func rangeWithTagSearch(priceMin: Int, priceMax: Int, tag: String) throws -> SearchResult<ProductRecord> {
        guard let realm = self.realm else {
            throw RealmRelationalSearcherError.notInitialized
        }

        let results = realm.objects(RealmProductRecord.self)
            .where {
                $0.price >= priceMin &&
                $0.price <= priceMax &&
                $0.tags.contains(tag)
            }
            .freeze()

        let models = Array(results.map { $0.toProductRecord() })
        return SearchResult(results: models, count: models.count)
    }

    /// Relational-03: Complex + Tag Search (복합 조건 + 태그)
    /// - Parameters:
    ///   - category: 카테고리
    ///   - priceMin: 최소 가격
    ///   - priceMax: 최대 가격
    ///   - dateFrom: 시작 날짜
    ///   - tag: 필터링할 태그
    /// - Returns: 검색 결과
    func complexWithTagSearch(
        category: String,
        priceMin: Int,
        priceMax: Int,
        dateFrom: Date,
        tag: String
    ) throws -> SearchResult<ProductRecord> {
        guard let realm = self.realm else {
            throw RealmRelationalSearcherError.notInitialized
        }

        let results = realm.objects(RealmProductRecord.self)
            .where {
                $0.category == category &&
                $0.price >= priceMin &&
                $0.price <= priceMax &&
                $0.date >= dateFrom &&
                $0.tags.contains(tag)
            }
            .freeze()

        let models = Array(results.map { $0.toProductRecord() })
        return SearchResult(results: models, count: models.count)
    }

    /// Relational-04: Full-Text + Tag Search (전문 검색 + 태그)
    /// - Parameters:
    ///   - keyword: 검색 키워드
    ///   - tag: 필터링할 태그
    /// - Returns: 검색 결과
    func fullTextWithTagSearch(keyword: String, tag: String) throws -> SearchResult<ProductRecord> {
        guard let realm = self.realm else {
            throw RealmRelationalSearcherError.notInitialized
        }

        let results = realm.objects(RealmProductRecord.self)
            .where {
                $0.descriptionText.contains(keyword, options: .caseInsensitive) &&
                $0.tags.contains(tag)
            }
            .freeze()

        let models = Array(results.map { $0.toProductRecord() })
        return SearchResult(results: models, count: models.count)
    }

    /// Relational-05: Multiple Tags Search (다중 태그 AND)
    /// - Parameters:
    ///   - tags: 검색할 태그 배열 (모두 포함되어야 함)
    /// - Returns: 검색 결과
    func searchByMultipleTags(_ tags: [String]) throws -> SearchResult<ProductRecord> {
        guard let realm = self.realm else {
            throw RealmRelationalSearcherError.notInitialized
        }

        var results = realm.objects(RealmProductRecord.self)

        // 모든 태그를 포함하는 레코드만 필터링
        for tag in tags {
            results = results.where { $0.tags.contains(tag) }
        }

        let frozenResults = results.freeze()
        let models = Array(frozenResults.map { $0.toProductRecord() })
        return SearchResult(results: models, count: models.count)
    }

    // MARK: - Cleanup

    /// DB 정리
    func cleanup() throws {
        guard let realm = self.realm else { return }

        try realm.write {
            realm.deleteAll()
        }
    }

    /// DB 파일 삭제
    func deleteDatabase() throws {
        self.realm = nil
        let fileURL = URL(fileURLWithPath: dbPath)

        if FileManager.default.fileExists(atPath: dbPath) {
            try FileManager.default.removeItem(at: fileURL)
        }

        let lockPath = dbPath + ".lock"
        let managementPath = dbPath + ".management"

        if FileManager.default.fileExists(atPath: lockPath) {
            try? FileManager.default.removeItem(atPath: lockPath)
        }
        if FileManager.default.fileExists(atPath: managementPath) {
            try? FileManager.default.removeItem(atPath: managementPath)
        }
    }
}

// MARK: - Realm Model

/// Realm용 ProductRecord 래퍼
final class RealmProductRecord: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted(indexed: true) var name: String
    @Persisted(indexed: true) var category: String
    @Persisted var price: Int
    @Persisted var date: Date
    @Persisted var descriptionText: String
    @Persisted var isActive: Bool
    @Persisted var tags: List<String>

    convenience init(from model: ProductRecord) {
        self.init()
        self.id = model.id
        self.name = model.name
        self.category = model.category
        self.price = model.price
        self.date = model.date
        self.descriptionText = model.description
        self.isActive = model.isActive

        let tagList = List<String>()
        model.tags.forEach { tagList.append($0) }
        self.tags = tagList
    }

    func toProductRecord() -> ProductRecord {
        ProductRecord(
            id: id,
            name: name,
            category: category,
            price: price,
            date: date,
            description: descriptionText,
            isActive: isActive,
            tags: Array(tags)
        )
    }
}

// MARK: - Errors

enum RealmRelationalSearcherError: Error, CustomStringConvertible {
    case notInitialized
    case dataVerificationFailed(expected: Int, actual: Int)

    var description: String {
        switch self {
        case .notInitialized:
            return "Realm not initialized. Call initializeDB() first."
        case .dataVerificationFailed(let expected, let actual):
            return "Data verification failed: expected \(expected), but got \(actual)"
        }
    }
}
