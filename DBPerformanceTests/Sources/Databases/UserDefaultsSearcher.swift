//
//  UserDefaultsSearcher.swift
//  DBPerformanceTests
//
//  UserDefaults 검색 구현
//  [CR-40] 구체 타입 사용: 프로토콜 제거, DB별 독립 Searcher 클래스
//
//  주의: 1M 데이터는 메모리 초과 위험 (권장 최대 100K)
//

import Foundation

/// UserDefaults 검색 구현 클래스
/// - 메모리 기반 전체 스캔
/// - 인덱스 미지원
@MainActor
final class UserDefaultsSearcher {
    private let defaults: UserDefaults
    private let storageKey = "flat_models_storage"

    private var models: [FlatModel] = []

    init(suiteName: String? = "com.dbperformance.search") {
        if let name = suiteName {
            self.defaults = UserDefaults(suiteName: name) ?? UserDefaults.standard
        } else {
            self.defaults = UserDefaults.standard
        }
    }

    // MARK: - Initialization

    /// DB 초기화
    func initializeDB() throws {
        // UserDefaults는 초기화 불필요
        self.models = []
    }

    /// Fixture에서 데이터 로드
    /// - Parameter path: Fixture 파일 경로
    /// - Returns: 로딩 시간
    func loadFromFixture(path: String) async throws -> Duration {
        // Fixture 로드
        let loadedModels = try await FixtureLoader.loadFlat(from: path)

        // 시간 측정
        let clock = ContinuousClock()
        let duration = clock.measure {
            // JSON 인코딩
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601

            if let data = try? encoder.encode(loadedModels) {
                defaults.set(data, forKey: storageKey)
                defaults.synchronize()
            }

            // 메모리에도 캐시
            self.models = loadedModels
        }

        // 데이터 검증
        guard self.models.count == loadedModels.count else {
            throw UserDefaultsSearcherError.dataVerificationFailed(
                expected: loadedModels.count,
                actual: self.models.count
            )
        }

        return duration
    }

    // MARK: - Search Methods (Full Scan)

    /// TM-08: Equality Search
    /// - 주의: 전체 스캔 (인덱스 미지원)
    func searchByName(_ name: String, indexed: Bool = false) throws -> SearchResult<FlatModel> {
        loadFromDefaultsIfNeeded()

        let results = models.filter { $0.name == name }
        return SearchResult(results: results, count: results.count)
    }

    /// TM-09: Range Search
    func rangeSearch(priceMin: Int, priceMax: Int) throws -> SearchResult<FlatModel> {
        loadFromDefaultsIfNeeded()

        let results = models.filter { $0.price >= priceMin && $0.price <= priceMax }
        return SearchResult(results: results, count: results.count)
    }

    /// TM-10: Complex Condition Search
    func complexSearch(
        category: String,
        priceMin: Int,
        priceMax: Int,
        dateFrom: Date
    ) throws -> SearchResult<FlatModel> {
        loadFromDefaultsIfNeeded()

        let results = models.filter {
            $0.category == category &&
            $0.price >= priceMin &&
            $0.price <= priceMax &&
            $0.date >= dateFrom
        }

        return SearchResult(results: results, count: results.count)
    }

    /// TM-11: Full-Text Search
    func fullTextSearch(_ keyword: String) throws -> SearchResult<FlatModel> {
        loadFromDefaultsIfNeeded()

        let results = models.filter {
            $0.description.localizedCaseInsensitiveContains(keyword)
        }

        return SearchResult(results: results, count: results.count)
    }

    /// Category Search
    func searchByCategory(_ category: String, indexed: Bool = false) throws -> SearchResult<FlatModel> {
        loadFromDefaultsIfNeeded()

        let results = models.filter { $0.category == category }
        return SearchResult(results: results, count: results.count)
    }

    // MARK: - Cleanup

    func cleanup() throws {
        self.models = []
        defaults.removeObject(forKey: storageKey)
        defaults.synchronize()
    }

    func deleteDatabase() throws {
        try cleanup()
    }

    // MARK: - Helpers

    private func loadFromDefaultsIfNeeded() {
        guard models.isEmpty else { return }

        if let data = defaults.data(forKey: storageKey) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            if let loaded = try? decoder.decode([FlatModel].self, from: data) {
                self.models = loaded
            }
        }
    }
}

// MARK: - Errors

enum UserDefaultsSearcherError: Error, CustomStringConvertible {
    case dataVerificationFailed(expected: Int, actual: Int)

    var description: String {
        switch self {
        case .dataVerificationFailed(let expected, let actual):
            return "Data verification failed: expected \(expected), but got \(actual)"
        }
    }
}
