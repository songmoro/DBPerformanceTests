import Foundation
import CoreData

actor CoreDataAdapter: DatabaseAdapter, FlushableAdapter {
    typealias Model = SimpleModel

    nonisolated(unsafe) private var persistentContainer: NSPersistentContainer?
    nonisolated(unsafe) private var context: NSManagedObjectContext?

    // 성능 최적화: Save 배칭
    nonisolated(unsafe) private var pendingSaveCount: Int = 0
    private let batchSaveThreshold: Int = 1000

    nonisolated var version: String { "CoreData (Optimized)" }
    nonisolated var name: String { "CoreData" }

    func initialize() async throws {
        let model = Self.createManagedObjectModel()
        let container = NSPersistentContainer(name: "SimpleModelCD", managedObjectModel: model)

        // 명시적으로 디스크 저장소 설정 (In-Memory 아님)
        let storeURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("SimpleModelCD.sqlite")

        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        storeDescription.type = NSSQLiteStoreType // SQLite 디스크 저장
        storeDescription.shouldAddStoreAsynchronously = false

        container.persistentStoreDescriptions = [storeDescription]

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            container.loadPersistentStores { description, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    print("CoreData store loaded at: \(description.url?.path ?? "unknown")")
                    continuation.resume()
                }
            }
        }

        self.persistentContainer = container
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        // 성능 최적화 설정
        context.undoManager = nil  // Undo 비활성화
        context.shouldDeleteInaccessibleFaults = true
        context.automaticallyMergesChangesFromParent = false

        self.context = context
    }

    func create(_ model: Model) async throws {
        guard let context = context else { throw DatabaseError.notFound }

        // NSManagedObject 서브클래스 사용 (KVC 대신 직접 접근)
        SimpleModelCD.create(from: model, in: context)

        // 배치 save: 일정 개수마다만 저장
        pendingSaveCount += 1
        if pendingSaveCount >= batchSaveThreshold {
            try context.save()
            pendingSaveCount = 0
            context.reset()  // 메모리 정리
        }
    }

    func createBatch(_ models: [Model]) async throws {
        guard let context = context else { throw DatabaseError.notFound }

        // NSManagedObject 서브클래스로 배치 삽입
        for model in models {
            SimpleModelCD.create(from: model, in: context)
        }

        try context.save()
        context.reset()  // 메모리 정리
    }

    func read(id: String) async throws -> Model? {
        guard let context = context else { throw DatabaseError.notFound }

        let request = NSFetchRequest<SimpleModelCD>(entityName: "SimpleModelCD")
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        request.returnsObjectsAsFaults = false  // Fault 최소화

        let results = try context.fetch(request)
        return results.first?.toSimpleModel()
    }

    nonisolated func searchIndexed(field: String, value: Any) async throws -> [Model] {
        // CoreData는 인덱스 설정 가능하지만 여기서는 동일하게 처리
        return try await search(field: field, value: value)
    }

    nonisolated func searchNonIndexed(field: String, value: Any) async throws -> [Model] {
        return try await search(field: field, value: value)
    }

    nonisolated func executeComplexQuery() async throws -> [Model] {
        guard let context = context else { throw DatabaseError.notFound }

        let request = NSFetchRequest<SimpleModelCD>(entityName: "SimpleModelCD")
        request.predicate = NSPredicate(format: "age > 25 AND isActive == TRUE AND score > 50.0")
        request.returnsObjectsAsFaults = false

        let results = try context.fetch(request)
        return results.map { $0.toSimpleModel() }
    }

    nonisolated func update(id: String, updates: [String: Any]) async throws {
        guard let context = context else { throw DatabaseError.notFound }

        let request = NSFetchRequest<SimpleModelCD>(entityName: "SimpleModelCD")
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1

        guard let entity = try context.fetch(request).first else {
            throw DatabaseError.notFound
        }

        // NSManagedObject 서브클래스로 직접 접근
        if let name = updates["name"] as? String {
            entity.name = name
        }
        if let age = updates["age"] as? Int {
            entity.age = age
        }
        if let score = updates["score"] as? Double {
            entity.score = score
        }
        if let isActive = updates["isActive"] as? Bool {
            entity.isActive = isActive
        }

        try context.save()
    }

    nonisolated func executeTransaction(operations: @Sendable () async throws -> Void) async throws {
        guard let context = context else { throw DatabaseError.notFound }

        try await operations()
        try context.save()
    }

    nonisolated func executeConcurrent(operations: [@Sendable () async throws -> Void]) async throws {
        // NSManagedObjectContext는 thread-safe하지 않으므로 actor isolation으로 순차 실행
        for operation in operations {
            try await operation()
        }
    }

    func delete(id: String) async throws {
        guard let context = context else { throw DatabaseError.notFound }

        let request = NSFetchRequest<SimpleModelCD>(entityName: "SimpleModelCD")
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        request.includesPropertyValues = false  // 프로퍼티 로드 안함 (삭제만 할 것이므로)

        guard let entity = try context.fetch(request).first else {
            throw DatabaseError.notFound
        }

        context.delete(entity)

        // 배치 delete: 일정 개수마다만 저장
        pendingSaveCount += 1
        if pendingSaveCount >= batchSaveThreshold {
            try context.save()
            pendingSaveCount = 0
            context.reset()
        }
    }

    func deleteAll() async throws {
        guard let context = context else { throw DatabaseError.notFound }

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "SimpleModelCD")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

        try context.execute(deleteRequest)
        try context.save()
    }

    func cleanup() async throws {
        // Context reset 후 batch delete
        guard let context = context, let container = persistentContainer else { return }

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "SimpleModelCD")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        deleteRequest.resultType = .resultTypeObjectIDs

        if let result = try context.execute(deleteRequest) as? NSBatchDeleteResult,
           let objectIDs = result.result as? [NSManagedObjectID] {
            NSManagedObjectContext.mergeChanges(
                fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
                into: [context]
            )
        }

        context.reset()

        // Persistent store 제거 및 파일 삭제
        let coordinator = container.persistentStoreCoordinator
        for store in coordinator.persistentStores {
            if let url = store.url {
                try coordinator.remove(store)
                try? FileManager.default.removeItem(at: url)

                // WAL 및 SHM 파일도 삭제
                let walURL = url.deletingPathExtension().appendingPathExtension("sqlite-wal")
                let shmURL = url.deletingPathExtension().appendingPathExtension("sqlite-shm")
                try? FileManager.default.removeItem(at: walURL)
                try? FileManager.default.removeItem(at: shmURL)
            }
        }

        // 참조 해제
        self.context = nil
        self.persistentContainer = nil
    }

    // MARK: - Private Helpers

    private static func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let entity = NSEntityDescription()
        entity.name = "SimpleModelCD"
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .stringAttributeType
        idAttribute.isOptional = false

        let nameAttribute = NSAttributeDescription()
        nameAttribute.name = "name"
        nameAttribute.attributeType = .stringAttributeType
        nameAttribute.isOptional = false

        let ageAttribute = NSAttributeDescription()
        ageAttribute.name = "age"
        ageAttribute.attributeType = .integer64AttributeType
        ageAttribute.isOptional = false

        let scoreAttribute = NSAttributeDescription()
        scoreAttribute.name = "score"
        scoreAttribute.attributeType = .doubleAttributeType
        scoreAttribute.isOptional = false

        let isActiveAttribute = NSAttributeDescription()
        isActiveAttribute.name = "isActive"
        isActiveAttribute.attributeType = .booleanAttributeType
        isActiveAttribute.isOptional = false

        let createdAtAttribute = NSAttributeDescription()
        createdAtAttribute.name = "createdAt"
        createdAtAttribute.attributeType = .dateAttributeType
        createdAtAttribute.isOptional = false

        entity.properties = [
            idAttribute,
            nameAttribute,
            ageAttribute,
            scoreAttribute,
            isActiveAttribute,
            createdAtAttribute
        ]

        model.entities = [entity]
        return model
    }

    private nonisolated func search(field: String, value: Any) async throws -> [Model] {
        guard let context = context else { throw DatabaseError.notFound }

        let request = NSFetchRequest<SimpleModelCD>(entityName: "SimpleModelCD")
        request.returnsObjectsAsFaults = false

        // 타입별로 안전하게 predicate 생성
        let predicate: NSPredicate
        switch value {
        case let intValue as Int:
            predicate = NSPredicate(format: "%K == %d", field, intValue)
        case let doubleValue as Double:
            predicate = NSPredicate(format: "%K == %f", field, doubleValue)
        case let boolValue as Bool:
            predicate = NSPredicate(format: "%K == %@", field, NSNumber(value: boolValue))
        case let stringValue as String:
            predicate = NSPredicate(format: "%K == %@", field, stringValue)
        default:
            return []
        }

        request.predicate = predicate

        let results = try context.fetch(request)
        return results.map { $0.toSimpleModel() }
    }

    // 남은 변경사항 저장 (벤치마크 단계 종료 시 호출)
    func flush() async throws {
        guard let context = context, context.hasChanges else { return }
        try context.save()
        pendingSaveCount = 0
        context.reset()
    }
}
