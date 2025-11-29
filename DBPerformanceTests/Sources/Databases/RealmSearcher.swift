//
//  RealmSearcher.swift
//  DBPerformanceTests
//
//  Realm 데이터베이스 검색 구현
//  [CR-40] 구체 타입 사용: 프로토콜 제거, DB별 독립 Searcher 클래스
//

import Foundation
@preconcurrency import RealmSwift

/// Realm 검색 구현 클래스
/// - 프로토콜 없이 구체 타입으로 구현
/// - 4가지 검색 시나리오 지원
@MainActor
final class RealmSearcher {
    private var realm: Realm?
    private let dbPath: String

    init(dbPath: String = "search_test.realm") {
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
    /// [TM-34] 로딩 성능 측정: 파일 읽기 + 파싱 + DB 저장 총 시간(ms)
    /// - Parameter path: Fixture 파일 경로
    /// - Returns: 로딩 시간 (Duration)
    func loadFromFixture(path: String) async throws -> Duration {
        // Fixture 로드
        let models = try await FixtureLoader.loadFlat(from: path)

        // 시간 측정
        let clock = ContinuousClock()
        let duration = try clock.measure {
            guard let realm = self.realm else {
                throw RealmSearcherError.notInitialized
            }

            try realm.write {
                // 기존 데이터 삭제
                realm.deleteAll()

                // 배치 저장
                for model in models {
                    realm.add(RealmFlatModel(from: model))
                }
            }
        }

        // [TM-35] 로딩 후 데이터 검증
        let count = realm?.objects(RealmFlatModel.self).count ?? 0
        guard count == models.count else {
            throw RealmSearcherError.dataVerificationFailed(
                expected: models.count,
                actual: count
            )
        }

        return duration
    }

    // MARK: - Search Methods

    /// TM-08: Equality Search (단순 필드 검색)
    /// - Parameters:
    ///   - name: 검색할 상품명
    ///   - indexed: 인덱스 사용 여부 (Realm은 자동 최적화)
    /// - Returns: 검색 결과
    func searchByName(_ name: String, indexed: Bool = true) throws -> SearchResult {
        guard let realm = self.realm else {
            throw RealmSearcherError.notInitialized
        }

        let results = realm.objects(RealmFlatModel.self)
            .where { $0.name == name }
            .freeze()

        let models = Array(results.map { $0.toFlatModel() })
        return SearchResult(results: models, count: models.count)
    }

    /// TM-09: Range Search (범위 검색)
    /// - Parameters:
    ///   - priceMin: 최소 가격
    ///   - priceMax: 최대 가격
    /// - Returns: 검색 결과
    func rangeSearch(priceMin: Int, priceMax: Int) throws -> SearchResult {
        guard let realm = self.realm else {
            throw RealmSearcherError.notInitialized
        }

        let results = realm.objects(RealmFlatModel.self)
            .where { $0.price >= priceMin && $0.price <= priceMax }
            .freeze()

        let models = Array(results.map { $0.toFlatModel() })
        return SearchResult(results: models, count: models.count)
    }

    /// TM-10: Complex Condition Search (복합 조건 검색)
    /// - Parameters:
    ///   - category: 카테고리
    ///   - priceMin: 최소 가격
    ///   - priceMax: 최대 가격
    ///   - dateFrom: 시작 날짜
    /// - Returns: 검색 결과
    func complexSearch(
        category: String,
        priceMin: Int,
        priceMax: Int,
        dateFrom: Date
    ) throws -> SearchResult {
        guard let realm = self.realm else {
            throw RealmSearcherError.notInitialized
        }

        let results = realm.objects(RealmFlatModel.self)
            .where {
                $0.category == category &&
                $0.price >= priceMin &&
                $0.price <= priceMax &&
                $0.date >= dateFrom
            }
            .freeze()

        let models = Array(results.map { $0.toFlatModel() })
        return SearchResult(results: models, count: models.count)
    }

    /// TM-11: Full-Text Search (전문 검색)
    /// - Parameter keyword: 검색 키워드
    /// - Returns: 검색 결과
    func fullTextSearch(_ keyword: String) throws -> SearchResult {
        guard let realm = self.realm else {
            throw RealmSearcherError.notInitialized
        }

        let results = realm.objects(RealmFlatModel.self)
            .where { $0.descriptionText.contains(keyword, options: .caseInsensitive) }
            .freeze()

        let models = Array(results.map { $0.toFlatModel() })
        return SearchResult(results: models, count: models.count)
    }

    /// 카테고리 검색 (인덱스 효과 측정용)
    /// - Parameters:
    ///   - category: 카테고리
    ///   - indexed: 인덱스 사용 여부
    /// - Returns: 검색 결과
    func searchByCategory(_ category: String, indexed: Bool = true) throws -> SearchResult {
        guard let realm = self.realm else {
            throw RealmSearcherError.notInitialized
        }

        let results = realm.objects(RealmFlatModel.self)
            .where { $0.category == category }
            .freeze()

        let models = Array(results.map { $0.toFlatModel() })
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

        // .lock 및 .management 파일도 삭제
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

/// Realm용 FlatModel 래퍼
final class RealmFlatModel: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted(indexed: true) var name: String
    @Persisted(indexed: true) var category: String
    @Persisted var price: Int
    @Persisted var date: Date
    @Persisted var descriptionText: String
    @Persisted var isActive: Bool

    convenience init(from model: FlatModel) {
        self.init()
        self.id = model.id
        self.name = model.name
        self.category = model.category
        self.price = model.price
        self.date = model.date
        self.descriptionText = model.description
        self.isActive = model.isActive
    }

    func toFlatModel() -> FlatModel {
        FlatModel(
            id: id,
            name: name,
            category: category,
            price: price,
            date: date,
            description: descriptionText,
            isActive: isActive
        )
    }
}

// MARK: - Errors

enum RealmSearcherError: Error, CustomStringConvertible {
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
