//
//  CoreDataSearcher.swift
//  DBPerformanceTests
//
//  CoreData 데이터베이스 검색 구현
//  [CR-40] 구체 타입 사용: 프로토콜 제거, DB별 독립 Searcher 클래스
//

import Foundation
import CoreData

/// CoreData 검색 구현 클래스
@MainActor
final class CoreDataSearcher {
    private var container: NSPersistentContainer?
    private let dbName: String

    init(dbName: String = "SearchTest") {
        self.dbName = dbName
    }

    // MARK: - Initialization

    /// DB 초기화
    func initializeDB() throws {
        // NSManagedObjectModel 생성
        let model = createManagedObjectModel()

        // NSPersistentContainer 생성
        let container = NSPersistentContainer(name: dbName, managedObjectModel: model)

        // Store 경로 설정
        let storeURL = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(dbName).sqlite")

        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [storeDescription]

        // Store 로드
        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }

        if let error = loadError {
            throw error
        }

        self.container = container
    }

    /// Fixture에서 데이터 로드
    /// - Parameter path: Fixture 파일 경로
    /// - Returns: 로딩 시간
    func loadFromFixture(path: String) async throws -> Duration {
        guard let container = self.container else {
            throw CoreDataSearcherError.notInitialized
        }

        // Fixture 로드
        let models = try await FixtureLoader.loadFlat(from: path)

        // 시간 측정
        let clock = ContinuousClock()
        let duration = clock.measure {
            let context = container.newBackgroundContext()

            context.performAndWait {
                // 기존 데이터 삭제
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FlatModelEntity")
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                try? context.execute(deleteRequest)

                // 배치 저장
                for model in models {
                    let entity = NSEntityDescription.insertNewObject(
                        forEntityName: "FlatModelEntity",
                        into: context
                    )
                    entity.setValue(model.id, forKey: "id")
                    entity.setValue(model.name, forKey: "name")
                    entity.setValue(model.category, forKey: "category")
                    entity.setValue(model.price, forKey: "price")
                    entity.setValue(model.date, forKey: "date")
                    entity.setValue(model.description, forKey: "descriptionText")
                    entity.setValue(model.isActive, forKey: "isActive")
                }

                try? context.save()
            }
        }

        // 데이터 검증
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FlatModelEntity")
        let count = try context.count(for: fetchRequest)

        guard count == models.count else {
            throw CoreDataSearcherError.dataVerificationFailed(
                expected: models.count,
                actual: count
            )
        }

        return duration
    }

    // MARK: - Search Methods

    /// TM-08: Equality Search
    func searchByName(_ name: String, indexed: Bool = true) throws -> SearchResult {
        guard let container = self.container else {
            throw CoreDataSearcherError.notInitialized
        }

        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FlatModelEntity")
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)

        let results = try context.fetch(fetchRequest)
        let models = results.map { convertToFlatModel($0) }

        return SearchResult(results: models, count: models.count)
    }

    /// TM-09: Range Search
    func rangeSearch(priceMin: Int, priceMax: Int) throws -> SearchResult {
        guard let container = self.container else {
            throw CoreDataSearcherError.notInitialized
        }

        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FlatModelEntity")
        fetchRequest.predicate = NSPredicate(
            format: "price >= %d AND price <= %d",
            priceMin,
            priceMax
        )

        let results = try context.fetch(fetchRequest)
        let models = results.map { convertToFlatModel($0) }

        return SearchResult(results: models, count: models.count)
    }

    /// TM-10: Complex Condition Search
    func complexSearch(
        category: String,
        priceMin: Int,
        priceMax: Int,
        dateFrom: Date
    ) throws -> SearchResult {
        guard let container = self.container else {
            throw CoreDataSearcherError.notInitialized
        }

        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FlatModelEntity")
        fetchRequest.predicate = NSPredicate(
            format: "category == %@ AND price >= %d AND price <= %d AND date >= %@",
            category,
            priceMin,
            priceMax,
            dateFrom as NSDate
        )

        let results = try context.fetch(fetchRequest)
        let models = results.map { convertToFlatModel($0) }

        return SearchResult(results: models, count: models.count)
    }

    /// TM-11: Full-Text Search
    func fullTextSearch(_ keyword: String) throws -> SearchResult {
        guard let container = self.container else {
            throw CoreDataSearcherError.notInitialized
        }

        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FlatModelEntity")
        fetchRequest.predicate = NSPredicate(
            format: "descriptionText CONTAINS[cd] %@",
            keyword
        )

        let results = try context.fetch(fetchRequest)
        let models = results.map { convertToFlatModel($0) }

        return SearchResult(results: models, count: models.count)
    }

    /// Category Search (인덱스 효과 측정용)
    func searchByCategory(_ category: String, indexed: Bool = true) throws -> SearchResult {
        guard let container = self.container else {
            throw CoreDataSearcherError.notInitialized
        }

        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FlatModelEntity")
        fetchRequest.predicate = NSPredicate(format: "category == %@", category)

        let results = try context.fetch(fetchRequest)
        let models = results.map { convertToFlatModel($0) }

        return SearchResult(results: models, count: models.count)
    }

    // MARK: - Cleanup

    func cleanup() throws {
        guard let container = self.container else { return }

        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FlatModelEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        try context.execute(deleteRequest)
        try context.save()
    }

    func deleteDatabase() throws {
        self.container = nil

        let fileURL = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(dbName).sqlite")

        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }

        // -shm, -wal 파일도 삭제
        let shmURL = fileURL.appendingPathExtension("sqlite-shm")
        let walURL = fileURL.appendingPathExtension("sqlite-wal")

        try? FileManager.default.removeItem(at: shmURL)
        try? FileManager.default.removeItem(at: walURL)
    }

    // MARK: - Helpers

    private func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // FlatModelEntity 정의
        let entity = NSEntityDescription()
        entity.name = "FlatModelEntity"
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        // 속성 정의
        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .stringAttributeType
        idAttr.isOptional = false

        let nameAttr = NSAttributeDescription()
        nameAttr.name = "name"
        nameAttr.attributeType = .stringAttributeType
        nameAttr.isIndexed = true  // 인덱스 적용

        let categoryAttr = NSAttributeDescription()
        categoryAttr.name = "category"
        categoryAttr.attributeType = .stringAttributeType
        categoryAttr.isIndexed = true  // 인덱스 적용

        let priceAttr = NSAttributeDescription()
        priceAttr.name = "price"
        priceAttr.attributeType = .integer32AttributeType

        let dateAttr = NSAttributeDescription()
        dateAttr.name = "date"
        dateAttr.attributeType = .dateAttributeType

        let descAttr = NSAttributeDescription()
        descAttr.name = "descriptionText"
        descAttr.attributeType = .stringAttributeType

        let activeAttr = NSAttributeDescription()
        activeAttr.name = "isActive"
        activeAttr.attributeType = .booleanAttributeType

        entity.properties = [idAttr, nameAttr, categoryAttr, priceAttr, dateAttr, descAttr, activeAttr]

        model.entities = [entity]
        return model
    }

    private func convertToFlatModel(_ object: NSManagedObject) -> FlatModel {
        FlatModel(
            id: object.value(forKey: "id") as? String ?? "",
            name: object.value(forKey: "name") as? String ?? "",
            category: object.value(forKey: "category") as? String ?? "",
            price: object.value(forKey: "price") as? Int ?? 0,
            date: object.value(forKey: "date") as? Date ?? Date(),
            description: object.value(forKey: "descriptionText") as? String ?? "",
            isActive: object.value(forKey: "isActive") as? Bool ?? false
        )
    }
}

// MARK: - Errors

enum CoreDataSearcherError: Error, CustomStringConvertible {
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
