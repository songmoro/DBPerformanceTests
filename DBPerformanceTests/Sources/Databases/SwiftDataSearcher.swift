//
//  SwiftDataSearcher.swift
//  DBPerformanceTests
//
//  SwiftData 데이터베이스 검색 구현
//  [CR-40] 구체 타입 사용: 프로토콜 제거, DB별 독립 Searcher 클래스
//
//  주의: macOS 15.0+ 필요
//

import Foundation
import SwiftData

/// SwiftData 검색 구현 클래스
@available(macOS 15.0, *)
@MainActor
final class SwiftDataSearcher {
    private var container: ModelContainer?
    private var context: ModelContext?

    init() {}

    // MARK: - Initialization

    /// DB 초기화
    func initializeDB() throws {
        let schema = Schema([SwiftDataFlatModel.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        let container = try ModelContainer(for: schema, configurations: [configuration])
        self.container = container
        self.context = ModelContext(container)
    }

    /// Fixture에서 데이터 로드
    /// - Parameter path: Fixture 파일 경로
    /// - Returns: 로딩 시간
    func loadFromFixture(path: String) async throws -> Duration {
        guard let context = self.context else {
            throw SwiftDataSearcherError.notInitialized
        }

        // Fixture 로드
        let models = try await FixtureLoader.loadFlat(from: path)

        // 시간 측정
        let clock = ContinuousClock()
        let duration = clock.measure {
            // 기존 데이터 삭제
            try? context.delete(model: SwiftDataFlatModel.self)

            // 배치 저장
            for model in models {
                context.insert(SwiftDataFlatModel(from: model))
            }

            try? context.save()
        }

        // 데이터 검증
        let descriptor = FetchDescriptor<SwiftDataFlatModel>()
        let count = try context.fetchCount(descriptor)

        guard count == models.count else {
            throw SwiftDataSearcherError.dataVerificationFailed(
                expected: models.count,
                actual: count
            )
        }

        return duration
    }

    // MARK: - Search Methods

    /// TM-08: Equality Search
    func searchByName(_ name: String, indexed: Bool = true) throws -> SearchResult {
        guard let context = self.context else {
            throw SwiftDataSearcherError.notInitialized
        }

        let predicate = #Predicate<SwiftDataFlatModel> { $0.name == name }
        var descriptor = FetchDescriptor<SwiftDataFlatModel>(predicate: predicate)

        let results = try context.fetch(descriptor)
        let models = results.map { $0.toFlatModel() }

        return SearchResult(results: models, count: models.count)
    }

    /// TM-09: Range Search
    func rangeSearch(priceMin: Int, priceMax: Int) throws -> SearchResult {
        guard let context = self.context else {
            throw SwiftDataSearcherError.notInitialized
        }

        let predicate = #Predicate<SwiftDataFlatModel> {
            $0.price >= priceMin && $0.price <= priceMax
        }
        var descriptor = FetchDescriptor<SwiftDataFlatModel>(predicate: predicate)

        let results = try context.fetch(descriptor)
        let models = results.map { $0.toFlatModel() }

        return SearchResult(results: models, count: models.count)
    }

    /// TM-10: Complex Condition Search
    func complexSearch(
        category: String,
        priceMin: Int,
        priceMax: Int,
        dateFrom: Date
    ) throws -> SearchResult {
        guard let context = self.context else {
            throw SwiftDataSearcherError.notInitialized
        }

        let predicate = #Predicate<SwiftDataFlatModel> {
            $0.category == category &&
            $0.price >= priceMin &&
            $0.price <= priceMax &&
            $0.date >= dateFrom
        }
        var descriptor = FetchDescriptor<SwiftDataFlatModel>(predicate: predicate)

        let results = try context.fetch(descriptor)
        let models = results.map { $0.toFlatModel() }

        return SearchResult(results: models, count: models.count)
    }

    /// TM-11: Full-Text Search
    func fullTextSearch(_ keyword: String) throws -> SearchResult {
        guard let context = self.context else {
            throw SwiftDataSearcherError.notInitialized
        }

        let predicate = #Predicate<SwiftDataFlatModel> {
            $0.descriptionText.contains(keyword)
        }
        var descriptor = FetchDescriptor<SwiftDataFlatModel>(predicate: predicate)

        let results = try context.fetch(descriptor)
        let models = results.map { $0.toFlatModel() }

        return SearchResult(results: models, count: models.count)
    }

    /// Category Search
    func searchByCategory(_ category: String, indexed: Bool = true) throws -> SearchResult {
        guard let context = self.context else {
            throw SwiftDataSearcherError.notInitialized
        }

        let predicate = #Predicate<SwiftDataFlatModel> { $0.category == category }
        var descriptor = FetchDescriptor<SwiftDataFlatModel>(predicate: predicate)

        let results = try context.fetch(descriptor)
        let models = results.map { $0.toFlatModel() }

        return SearchResult(results: models, count: models.count)
    }

    // MARK: - Cleanup

    func cleanup() throws {
        guard let context = self.context else { return }
        try context.delete(model: SwiftDataFlatModel.self)
        try context.save()
    }

    func deleteDatabase() throws {
        self.context = nil
        self.container = nil
    }
}

// MARK: - SwiftData Model

@available(macOS 15.0, *)
@Model
final class SwiftDataFlatModel {
    @Attribute(.unique) var id: String
    var name: String
    var category: String
    var price: Int
    var date: Date
    var descriptionText: String
    var isActive: Bool

    init(id: String, name: String, category: String, price: Int, date: Date, descriptionText: String, isActive: Bool) {
        self.id = id
        self.name = name
        self.category = category
        self.price = price
        self.date = date
        self.descriptionText = descriptionText
        self.isActive = isActive
    }

    convenience init(from model: FlatModel) {
        self.init(
            id: model.id,
            name: model.name,
            category: model.category,
            price: model.price,
            date: model.date,
            descriptionText: model.description,
            isActive: model.isActive
        )
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

enum SwiftDataSearcherError: Error, CustomStringConvertible {
    case notInitialized
    case dataVerificationFailed(expected: Int, actual: Int)

    var description: String {
        switch self {
        case .notInitialized:
            return "SwiftData not initialized. Call initializeDB() first."
        case .dataVerificationFailed(let expected, let actual):
            return "Data verification failed: expected \(expected), but got \(actual)"
        }
    }
}
