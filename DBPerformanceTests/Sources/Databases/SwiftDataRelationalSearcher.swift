//
//  SwiftDataRelationalSearcher.swift
//  DBPerformanceTests
//
//  SwiftData 관계형 검색 구현 (1:N - ProductRecord + Tags)
//

import Foundation
import SwiftData

/// SwiftData 관계형 검색 구현 클래스
@MainActor
final class SwiftDataRelationalSearcher {
    private var container: ModelContainer?
    private var context: ModelContext?

    init() {}

    // MARK: - Initialization

    /// DB 초기화
    func initializeDB() throws {
        let schema = Schema([ProductRecordModel.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container = try ModelContainer(for: schema, configurations: [configuration])

        self.container = container
        self.context = ModelContext(container)
    }

    /// Fixture에서 데이터 로드
    func loadFromFixture(path: String) async throws -> Duration {
        let models = try await RelationalFixtureLoader.loadRelational(from: path)

        guard let context = self.context else {
            throw SwiftDataRelationalSearcherError.notInitialized
        }

        let clock = ContinuousClock()
        let duration = try clock.measure {
            // 기존 데이터 삭제
            try context.delete(model: ProductRecordModel.self)

            // 배치 저장
            for model in models {
                let entity = ProductRecordModel(from: model)
                context.insert(entity)
            }

            try context.save()
        }

        // 검증
        let descriptor = FetchDescriptor<ProductRecordModel>()
        let count = try context.fetchCount(descriptor)
        guard count == models.count else {
            throw SwiftDataRelationalSearcherError.dataVerificationFailed(
                expected: models.count,
                actual: count
            )
        }

        return duration
    }

    // MARK: - Search Methods

    /// Relational-01: Tag Equality Search
    func searchByTag(_ tag: String, indexed: Bool = true) throws -> SearchResult<ProductRecord> {
        guard let context = self.context else {
            throw SwiftDataRelationalSearcherError.notInitialized
        }

        let descriptor = FetchDescriptor<ProductRecordModel>(
            predicate: #Predicate { product in
                product.tagsString.contains(tag)
            }
        )

        let entities = try context.fetch(descriptor)
        let models = entities.map { $0.toProductRecord() }
        return SearchResult(results: models, count: models.count)
    }

    /// Relational-02: Range + Tag Search
    func rangeWithTagSearch(priceMin: Int, priceMax: Int, tag: String) throws -> SearchResult<ProductRecord> {
        guard let context = self.context else {
            throw SwiftDataRelationalSearcherError.notInitialized
        }

        let descriptor = FetchDescriptor<ProductRecordModel>(
            predicate: #Predicate { product in
                product.price >= priceMin &&
                product.price <= priceMax &&
                product.tagsString.contains(tag)
            }
        )

        let entities = try context.fetch(descriptor)
        let models = entities.map { $0.toProductRecord() }
        return SearchResult(results: models, count: models.count)
    }

    /// Relational-03: Complex + Tag Search
    func complexWithTagSearch(
        category: String,
        priceMin: Int,
        priceMax: Int,
        dateFrom: Date,
        tag: String
    ) throws -> SearchResult<ProductRecord> {
        guard let context = self.context else {
            throw SwiftDataRelationalSearcherError.notInitialized
        }

        let descriptor = FetchDescriptor<ProductRecordModel>(
            predicate: #Predicate { product in
                product.category == category &&
                product.price >= priceMin &&
                product.price <= priceMax &&
                product.date >= dateFrom &&
                product.tagsString.contains(tag)
            }
        )

        let entities = try context.fetch(descriptor)
        let models = entities.map { $0.toProductRecord() }
        return SearchResult(results: models, count: models.count)
    }

    /// Relational-04: Full-Text + Tag Search
    func fullTextWithTagSearch(keyword: String, tag: String) throws -> SearchResult<ProductRecord> {
        guard let context = self.context else {
            throw SwiftDataRelationalSearcherError.notInitialized
        }

        let descriptor = FetchDescriptor<ProductRecordModel>(
            predicate: #Predicate { product in
                product.descriptionText.contains(keyword) &&
                product.tagsString.contains(tag)
            }
        )

        let entities = try context.fetch(descriptor)
        let models = entities.map { $0.toProductRecord() }
        return SearchResult(results: models, count: models.count)
    }

    /// Relational-05: Multiple Tags Search
    func searchByMultipleTags(_ tags: [String]) throws -> SearchResult<ProductRecord> {
        guard let context = self.context else {
            throw SwiftDataRelationalSearcherError.notInitialized
        }

        // SwiftData에서는 동적으로 여러 contains 조건을 만들기 어려우므로
        // 모든 태그를 포함하는지 직접 필터링
        let descriptor = FetchDescriptor<ProductRecordModel>()
        let allEntities = try context.fetch(descriptor)

        let filtered = allEntities.filter { product in
            tags.allSatisfy { product.tagsString.contains($0) }
        }

        let models = filtered.map { $0.toProductRecord() }
        return SearchResult(results: models, count: models.count)
    }

    // MARK: - Cleanup

    func cleanup() throws {
        guard let context = self.context else { return }

        try context.delete(model: ProductRecordModel.self)
        try context.save()
    }
}

// MARK: - SwiftData Model

@Model
final class ProductRecordModel {
    @Attribute(.unique) var id: String
    var name: String
    var category: String
    var price: Int
    var date: Date
    var descriptionText: String
    var isActive: Bool
    var tagsString: String // 쉼표로 구분된 문자열 저장

    init(id: String, name: String, category: String, price: Int, date: Date, descriptionText: String, isActive: Bool, tagsString: String) {
        self.id = id
        self.name = name
        self.category = category
        self.price = price
        self.date = date
        self.descriptionText = descriptionText
        self.isActive = isActive
        self.tagsString = tagsString
    }

    convenience init(from model: ProductRecord) {
        self.init(
            id: model.id,
            name: model.name,
            category: model.category,
            price: model.price,
            date: model.date,
            descriptionText: model.description,
            isActive: model.isActive,
            tagsString: model.tags.joined(separator: ",")
        )
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
            tags: tagsString.split(separator: ",").map(String.init)
        )
    }
}

// MARK: - Errors

enum SwiftDataRelationalSearcherError: Error, CustomStringConvertible {
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
