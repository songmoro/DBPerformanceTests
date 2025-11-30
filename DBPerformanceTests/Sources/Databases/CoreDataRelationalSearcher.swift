//
//  CoreDataRelationalSearcher.swift
//  DBPerformanceTests
//
//  CoreData 관계형 검색 구현 (1:N - ProductRecord + Tags)
//

import Foundation
import CoreData

/// CoreData 관계형 검색 구현 클래스
@MainActor
final class CoreDataRelationalSearcher {
    private var container: NSPersistentContainer?
    private let dbName: String

    init(dbName: String = "RelationalSearchTest") {
        self.dbName = dbName
    }

    // MARK: - Initialization

    /// DB 초기화
    func initializeDB() throws {
        let model = NSManagedObjectModel()

        // ProductRecordEntity 정의
        let productEntity = NSEntityDescription()
        productEntity.name = "ProductRecordEntity"
        productEntity.managedObjectClassName = NSStringFromClass(ProductRecordEntity.self)

        // Attributes
        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.type = .string
        idAttr.isOptional = false

        let nameAttr = NSAttributeDescription()
        nameAttr.name = "name"
        nameAttr.type = .string

        let categoryAttr = NSAttributeDescription()
        categoryAttr.name = "category"
        categoryAttr.type = .string

        let priceAttr = NSAttributeDescription()
        priceAttr.name = "price"
        priceAttr.type = .integer64

        let dateAttr = NSAttributeDescription()
        dateAttr.name = "date"
        dateAttr.type = .date

        let descriptionAttr = NSAttributeDescription()
        descriptionAttr.name = "descriptionText"
        descriptionAttr.type = .string

        let isActiveAttr = NSAttributeDescription()
        isActiveAttr.name = "isActive"
        isActiveAttr.type = .boolean

        let tagsAttr = NSAttributeDescription()
        tagsAttr.name = "tags"
        tagsAttr.type = .transformable
        tagsAttr.valueTransformerName = "NSSecureUnarchiveFromData"
        tagsAttr.allowsExternalBinaryDataStorage = false

        productEntity.properties = [
            idAttr, nameAttr, categoryAttr, priceAttr,
            dateAttr, descriptionAttr, isActiveAttr, tagsAttr
        ]

        model.entities = [productEntity]

        let container = NSPersistentContainer(name: dbName, managedObjectModel: model)
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }

        self.container = container
    }

    /// Fixture에서 데이터 로드
    func loadFromFixture(path: String) async throws -> Duration {
        let models = try await RelationalFixtureLoader.loadRelational(from: path)

        guard let context = container?.viewContext else {
            throw CoreDataRelationalSearcherError.notInitialized
        }

        let clock = ContinuousClock()
        let duration = try clock.measure {
            // 기존 데이터 삭제
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ProductRecordEntity")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try context.execute(deleteRequest)

            // 배치 저장
            for model in models {
                let entity = ProductRecordEntity(context: context)
                entity.id = model.id
                entity.name = model.name
                entity.category = model.category
                entity.price = Int64(model.price)
                entity.date = model.date
                entity.descriptionText = model.description
                entity.isActive = model.isActive
                entity.tags = model.tags as NSArray
            }

            try context.save()
        }

        // 검증
        let fetchRequest = NSFetchRequest<ProductRecordEntity>(entityName: "ProductRecordEntity")
        let count = try context.count(for: fetchRequest)
        guard count == models.count else {
            throw CoreDataRelationalSearcherError.dataVerificationFailed(
                expected: models.count,
                actual: count
            )
        }

        return duration
    }

    // MARK: - Search Methods

    /// Relational-01: Tag Equality Search
    func searchByTag(_ tag: String, indexed: Bool = true) throws -> SearchResult<ProductRecord> {
        guard let context = container?.viewContext else {
            throw CoreDataRelationalSearcherError.notInitialized
        }

        let fetchRequest = NSFetchRequest<ProductRecordEntity>(entityName: "ProductRecordEntity")
        fetchRequest.predicate = NSPredicate(format: "ANY tags == %@", tag)

        let entities = try context.fetch(fetchRequest)
        let models = entities.map { $0.toProductRecord() }
        return SearchResult(results: models, count: models.count)
    }

    /// Relational-02: Range + Tag Search
    func rangeWithTagSearch(priceMin: Int, priceMax: Int, tag: String) throws -> SearchResult<ProductRecord> {
        guard let context = container?.viewContext else {
            throw CoreDataRelationalSearcherError.notInitialized
        }

        let fetchRequest = NSFetchRequest<ProductRecordEntity>(entityName: "ProductRecordEntity")
        fetchRequest.predicate = NSPredicate(
            format: "price >= %d AND price <= %d AND ANY tags == %@",
            priceMin, priceMax, tag
        )

        let entities = try context.fetch(fetchRequest)
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
        guard let context = container?.viewContext else {
            throw CoreDataRelationalSearcherError.notInitialized
        }

        let fetchRequest = NSFetchRequest<ProductRecordEntity>(entityName: "ProductRecordEntity")
        fetchRequest.predicate = NSPredicate(
            format: "category == %@ AND price >= %d AND price <= %d AND date >= %@ AND ANY tags == %@",
            category, priceMin, priceMax, dateFrom as NSDate, tag
        )

        let entities = try context.fetch(fetchRequest)
        let models = entities.map { $0.toProductRecord() }
        return SearchResult(results: models, count: models.count)
    }

    /// Relational-04: Full-Text + Tag Search
    func fullTextWithTagSearch(keyword: String, tag: String) throws -> SearchResult<ProductRecord> {
        guard let context = container?.viewContext else {
            throw CoreDataRelationalSearcherError.notInitialized
        }

        let fetchRequest = NSFetchRequest<ProductRecordEntity>(entityName: "ProductRecordEntity")
        fetchRequest.predicate = NSPredicate(
            format: "descriptionText CONTAINS[cd] %@ AND ANY tags == %@",
            keyword, tag
        )

        let entities = try context.fetch(fetchRequest)
        let models = entities.map { $0.toProductRecord() }
        return SearchResult(results: models, count: models.count)
    }

    /// Relational-05: Multiple Tags Search
    func searchByMultipleTags(_ tags: [String]) throws -> SearchResult<ProductRecord> {
        guard let context = container?.viewContext else {
            throw CoreDataRelationalSearcherError.notInitialized
        }

        let fetchRequest = NSFetchRequest<ProductRecordEntity>(entityName: "ProductRecordEntity")

        // 모든 태그를 포함하는 조건 생성
        let predicates = tags.map { NSPredicate(format: "ANY tags == %@", $0) }
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        let entities = try context.fetch(fetchRequest)
        let models = entities.map { $0.toProductRecord() }
        return SearchResult(results: models, count: models.count)
    }

    // MARK: - Cleanup

    func cleanup() throws {
        guard let context = container?.viewContext else { return }

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ProductRecordEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try context.execute(deleteRequest)
        try context.save()
    }
}

// MARK: - Core Data Entity

@objc(ProductRecordEntity)
class ProductRecordEntity: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var name: String?
    @NSManaged var category: String?
    @NSManaged var price: Int64
    @NSManaged var date: Date?
    @NSManaged var descriptionText: String?
    @NSManaged var isActive: Bool
    @NSManaged var tags: NSArray?

    func toProductRecord() -> ProductRecord {
        ProductRecord(
            id: id,
            name: name ?? "",
            category: category ?? "",
            price: Int(price),
            date: date ?? Date(),
            description: descriptionText ?? "",
            isActive: isActive,
            tags: (tags as? [String]) ?? []
        )
    }
}

// MARK: - Errors

enum CoreDataRelationalSearcherError: Error, CustomStringConvertible {
    case notInitialized
    case dataVerificationFailed(expected: Int, actual: Int)

    var description: String {
        switch self {
        case .notInitialized:
            return "CoreData not initialized. Call initializeDB() first."
        case .dataVerificationFailed(let expected, let actual):
            return "Data verification failed: expected \(expected), but got \(actual)"
        }
    }
}
