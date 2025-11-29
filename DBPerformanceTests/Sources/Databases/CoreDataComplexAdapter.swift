import Foundation
import CoreData

actor CoreDataComplexAdapter: DatabaseAdapter, FlushableAdapter {
    typealias Model = ComplexModel

    nonisolated(unsafe) private var persistentContainer: NSPersistentContainer?
    nonisolated(unsafe) private var context: NSManagedObjectContext?

    // 성능 최적화: Save 배칭
    nonisolated(unsafe) private var pendingSaveCount: Int = 0
    private let batchSaveThreshold: Int = 100  // Complex 모델은 더 큰 단위로

    nonisolated var version: String { "CoreData (Optimized)" }
    nonisolated var name: String { "CoreData" }

    func initialize() async throws {
        let model = Self.createManagedObjectModel()
        let container = NSPersistentContainer(name: "ComplexModelCD", managedObjectModel: model)

        // 명시적으로 디스크 저장소 설정 (In-Memory 아님)
        let storeURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("ComplexModelCD.sqlite")

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
        context.undoManager = nil
        context.shouldDeleteInaccessibleFaults = true
        context.automaticallyMergesChangesFromParent = false

        self.context = context
    }

    func create(_ model: Model) async throws {
        guard let context = context else { throw DatabaseError.notFound }

        _ = createEntity(from: model, in: context)

        // 배치 save
        pendingSaveCount += 1
        if pendingSaveCount >= batchSaveThreshold {
            try context.save()
            pendingSaveCount = 0
            context.reset()
        }
    }

    func createBatch(_ models: [Model]) async throws {
        guard let context = context else { throw DatabaseError.notFound }

        for model in models {
            _ = createEntity(from: model, in: context)
        }

        try context.save()
        context.reset()
    }

    func read(id: String) async throws -> Model? {
        guard let context = context else { throw DatabaseError.notFound }

        let request = NSFetchRequest<NSManagedObject>(entityName: "ComplexModelCD")
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1

        let results = try context.fetch(request)
        return results.first.flatMap { try? convertToModel($0, context: context) }
    }

    nonisolated func searchIndexed(field: String, value: Any) async throws -> [Model] {
        return try await search(field: field, value: value)
    }

    nonisolated func searchNonIndexed(field: String, value: Any) async throws -> [Model] {
        return try await search(field: field, value: value)
    }

    nonisolated func executeComplexQuery() async throws -> [Model] {
        guard let context = context else { throw DatabaseError.notFound }

        let request = NSFetchRequest<NSManagedObject>(entityName: "ComplexModelCD")
        request.predicate = NSPredicate(format: "value > 500 AND isEnabled == TRUE AND score > 50.0")

        let results = try context.fetch(request)
        return results.compactMap { try? convertToModel($0, context: context) }
    }

    nonisolated func update(id: String, updates: [String: Any]) async throws {
        guard let context = context else { throw DatabaseError.notFound }

        let request = NSFetchRequest<NSManagedObject>(entityName: "ComplexModelCD")
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1

        guard let entity = try context.fetch(request).first else {
            throw DatabaseError.notFound
        }

        for (key, value) in updates {
            entity.setValue(value, forKey: key)
        }

        try context.save()
    }

    nonisolated func executeTransaction(operations: @Sendable () async throws -> Void) async throws {
        guard let context = context else { throw DatabaseError.notFound }

        try await operations()
        try context.save()
    }

    nonisolated func executeConcurrent(operations: [@Sendable () async throws -> Void]) async throws {
        for operation in operations {
            try await operation()
        }
    }

    func delete(id: String) async throws {
        guard let context = context else { throw DatabaseError.notFound }

        let request = NSFetchRequest<NSManagedObject>(entityName: "ComplexModelCD")
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        request.includesPropertyValues = false

        guard let entity = try context.fetch(request).first else {
            throw DatabaseError.notFound
        }

        context.delete(entity)

        // 배치 delete
        pendingSaveCount += 1
        if pendingSaveCount >= batchSaveThreshold {
            try context.save()
            pendingSaveCount = 0
            context.reset()
        }
    }

    func deleteAll() async throws {
        guard let context = context else { throw DatabaseError.notFound }

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ComplexModelCD")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

        try context.execute(deleteRequest)
        try context.save()
    }

    func cleanup() async throws {
        // Context reset 후 batch delete
        guard let context = context, let container = persistentContainer else { return }

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ComplexModelCD")
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

    // 남은 변경사항 저장
    func flush() async throws {
        guard let context = context, context.hasChanges else { return }
        try context.save()
        pendingSaveCount = 0
        context.reset()
    }

    // MARK: - Private Helpers

    private static func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // Level 5
        let level5Entity = NSEntityDescription()
        level5Entity.name = "ComplexModelLevel5CD"
        level5Entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        let level5Id = NSAttributeDescription()
        level5Id.name = "id"
        level5Id.attributeType = .stringAttributeType
        level5Id.isOptional = false

        let level5Note = NSAttributeDescription()
        level5Note.name = "note"
        level5Note.attributeType = .stringAttributeType
        level5Note.isOptional = false

        let level5Index = NSAttributeDescription()
        level5Index.name = "index"
        level5Index.attributeType = .integer64AttributeType
        level5Index.isOptional = false

        level5Entity.properties = [level5Id, level5Note, level5Index]

        // Level 4
        let level4Entity = NSEntityDescription()
        level4Entity.name = "ComplexModelLevel4CD"
        level4Entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        let level4Id = NSAttributeDescription()
        level4Id.name = "id"
        level4Id.attributeType = .stringAttributeType
        level4Id.isOptional = false

        let level4Description = NSAttributeDescription()
        level4Description.name = "descriptionText"
        level4Description.attributeType = .stringAttributeType
        level4Description.isOptional = false

        let level4Quantity = NSAttributeDescription()
        level4Quantity.name = "quantity"
        level4Quantity.attributeType = .integer64AttributeType
        level4Quantity.isOptional = false

        let level4ToLevel5 = NSRelationshipDescription()
        level4ToLevel5.name = "children"
        level4ToLevel5.destinationEntity = level5Entity
        level4ToLevel5.isOrdered = true
        level4ToLevel5.minCount = 0
        level4ToLevel5.maxCount = 0
        level4ToLevel5.deleteRule = .cascadeDeleteRule

        level4Entity.properties = [level4Id, level4Description, level4Quantity, level4ToLevel5]

        // Level 3
        let level3Entity = NSEntityDescription()
        level3Entity.name = "ComplexModelLevel3CD"
        level3Entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        let level3Id = NSAttributeDescription()
        level3Id.name = "id"
        level3Id.attributeType = .stringAttributeType
        level3Id.isOptional = false

        let level3Label = NSAttributeDescription()
        level3Label.name = "label"
        level3Label.attributeType = .stringAttributeType
        level3Label.isOptional = false

        let level3Amount = NSAttributeDescription()
        level3Amount.name = "amount"
        level3Amount.attributeType = .doubleAttributeType
        level3Amount.isOptional = false

        let level3ToLevel4 = NSRelationshipDescription()
        level3ToLevel4.name = "children"
        level3ToLevel4.destinationEntity = level4Entity
        level3ToLevel4.isOrdered = true
        level3ToLevel4.minCount = 0
        level3ToLevel4.maxCount = 0
        level3ToLevel4.deleteRule = .cascadeDeleteRule

        level3Entity.properties = [level3Id, level3Label, level3Amount, level3ToLevel4]

        // Level 2
        let level2Entity = NSEntityDescription()
        level2Entity.name = "ComplexModelLevel2CD"
        level2Entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        let level2Id = NSAttributeDescription()
        level2Id.name = "id"
        level2Id.attributeType = .stringAttributeType
        level2Id.isOptional = false

        let level2Title = NSAttributeDescription()
        level2Title.name = "title"
        level2Title.attributeType = .stringAttributeType
        level2Title.isOptional = false

        let level2Count = NSAttributeDescription()
        level2Count.name = "count"
        level2Count.attributeType = .integer64AttributeType
        level2Count.isOptional = false

        let level2ToLevel3 = NSRelationshipDescription()
        level2ToLevel3.name = "children"
        level2ToLevel3.destinationEntity = level3Entity
        level2ToLevel3.isOrdered = true
        level2ToLevel3.minCount = 0
        level2ToLevel3.maxCount = 0
        level2ToLevel3.deleteRule = .cascadeDeleteRule

        level2Entity.properties = [level2Id, level2Title, level2Count, level2ToLevel3]

        // Level 1 (Main)
        let mainEntity = NSEntityDescription()
        mainEntity.name = "ComplexModelCD"
        mainEntity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        let mainId = NSAttributeDescription()
        mainId.name = "id"
        mainId.attributeType = .stringAttributeType
        mainId.isOptional = false

        let mainName = NSAttributeDescription()
        mainName.name = "name"
        mainName.attributeType = .stringAttributeType
        mainName.isOptional = false

        let mainValue = NSAttributeDescription()
        mainValue.name = "value"
        mainValue.attributeType = .integer64AttributeType
        mainValue.isOptional = false

        let mainScore = NSAttributeDescription()
        mainScore.name = "score"
        mainScore.attributeType = .doubleAttributeType
        mainScore.isOptional = false

        let mainIsEnabled = NSAttributeDescription()
        mainIsEnabled.name = "isEnabled"
        mainIsEnabled.attributeType = .booleanAttributeType
        mainIsEnabled.isOptional = false

        let mainTimestamp = NSAttributeDescription()
        mainTimestamp.name = "timestamp"
        mainTimestamp.attributeType = .dateAttributeType
        mainTimestamp.isOptional = false

        let mainToLevel2 = NSRelationshipDescription()
        mainToLevel2.name = "children"
        mainToLevel2.destinationEntity = level2Entity
        mainToLevel2.isOrdered = true
        mainToLevel2.minCount = 0
        mainToLevel2.maxCount = 0
        mainToLevel2.deleteRule = .cascadeDeleteRule

        mainEntity.properties = [
            mainId, mainName, mainValue, mainScore, mainIsEnabled, mainTimestamp, mainToLevel2
        ]

        model.entities = [mainEntity, level2Entity, level3Entity, level4Entity, level5Entity]
        return model
    }

    @discardableResult
    private func createEntity(from model: ComplexModel, in context: NSManagedObjectContext) -> NSManagedObject {
        let entity = NSEntityDescription.insertNewObject(forEntityName: "ComplexModelCD", into: context)
        entity.setValue(model.id, forKey: "id")
        entity.setValue(model.name, forKey: "name")
        entity.setValue(model.value, forKey: "value")
        entity.setValue(model.score, forKey: "score")
        entity.setValue(model.isEnabled, forKey: "isEnabled")
        entity.setValue(model.timestamp, forKey: "timestamp")

        let childrenSet = NSMutableOrderedSet()
        for child in model.children {
            let childEntity = createLevel2Entity(from: child, in: context)
            childrenSet.add(childEntity)
        }
        entity.setValue(childrenSet, forKey: "children")

        return entity
    }

    private func createLevel2Entity(from model: ComplexModelLevel2, in context: NSManagedObjectContext) -> NSManagedObject {
        let entity = NSEntityDescription.insertNewObject(forEntityName: "ComplexModelLevel2CD", into: context)
        entity.setValue(model.id, forKey: "id")
        entity.setValue(model.title, forKey: "title")
        entity.setValue(model.count, forKey: "count")

        let childrenSet = NSMutableOrderedSet()
        for child in model.children {
            let childEntity = createLevel3Entity(from: child, in: context)
            childrenSet.add(childEntity)
        }
        entity.setValue(childrenSet, forKey: "children")

        return entity
    }

    private func createLevel3Entity(from model: ComplexModelLevel3, in context: NSManagedObjectContext) -> NSManagedObject {
        let entity = NSEntityDescription.insertNewObject(forEntityName: "ComplexModelLevel3CD", into: context)
        entity.setValue(model.id, forKey: "id")
        entity.setValue(model.label, forKey: "label")
        entity.setValue(model.amount, forKey: "amount")

        let childrenSet = NSMutableOrderedSet()
        for child in model.children {
            let childEntity = createLevel4Entity(from: child, in: context)
            childrenSet.add(childEntity)
        }
        entity.setValue(childrenSet, forKey: "children")

        return entity
    }

    private func createLevel4Entity(from model: ComplexModelLevel4, in context: NSManagedObjectContext) -> NSManagedObject {
        let entity = NSEntityDescription.insertNewObject(forEntityName: "ComplexModelLevel4CD", into: context)
        entity.setValue(model.id, forKey: "id")
        entity.setValue(model.description, forKey: "descriptionText")
        entity.setValue(model.quantity, forKey: "quantity")

        let childrenSet = NSMutableOrderedSet()
        for child in model.children {
            let childEntity = createLevel5Entity(from: child, in: context)
            childrenSet.add(childEntity)
        }
        entity.setValue(childrenSet, forKey: "children")

        return entity
    }

    private func createLevel5Entity(from model: ComplexModelLevel5, in context: NSManagedObjectContext) -> NSManagedObject {
        let entity = NSEntityDescription.insertNewObject(forEntityName: "ComplexModelLevel5CD", into: context)
        entity.setValue(model.id, forKey: "id")
        entity.setValue(model.note, forKey: "note")
        entity.setValue(model.index, forKey: "index")

        return entity
    }

    private nonisolated func convertToModel(_ object: NSManagedObject, context: NSManagedObjectContext) throws -> ComplexModel {
        guard
            let id = object.value(forKey: "id") as? String,
            let name = object.value(forKey: "name") as? String,
            let value = object.value(forKey: "value") as? Int,
            let score = object.value(forKey: "score") as? Double,
            let isEnabled = object.value(forKey: "isEnabled") as? Bool,
            let timestamp = object.value(forKey: "timestamp") as? Date
        else {
            throw DatabaseError.invalidData
        }

        var children: [ComplexModelLevel2] = []
        if let childrenSet = object.value(forKey: "children") as? NSOrderedSet {
            for case let childObject as NSManagedObject in childrenSet {
                if let child = try? convertToLevel2(childObject, context: context) {
                    children.append(child)
                }
            }
        }

        return ComplexModel(
            id: id,
            name: name,
            value: value,
            score: score,
            isEnabled: isEnabled,
            timestamp: timestamp,
            children: children
        )
    }

    private nonisolated func convertToLevel2(_ object: NSManagedObject, context: NSManagedObjectContext) throws -> ComplexModelLevel2 {
        guard
            let id = object.value(forKey: "id") as? String,
            let title = object.value(forKey: "title") as? String,
            let count = object.value(forKey: "count") as? Int
        else {
            throw DatabaseError.invalidData
        }

        var children: [ComplexModelLevel3] = []
        if let childrenSet = object.value(forKey: "children") as? NSOrderedSet {
            for case let childObject as NSManagedObject in childrenSet {
                if let child = try? convertToLevel3(childObject, context: context) {
                    children.append(child)
                }
            }
        }

        return ComplexModelLevel2(id: id, title: title, count: count, children: children)
    }

    private nonisolated func convertToLevel3(_ object: NSManagedObject, context: NSManagedObjectContext) throws -> ComplexModelLevel3 {
        guard
            let id = object.value(forKey: "id") as? String,
            let label = object.value(forKey: "label") as? String,
            let amount = object.value(forKey: "amount") as? Double
        else {
            throw DatabaseError.invalidData
        }

        var children: [ComplexModelLevel4] = []
        if let childrenSet = object.value(forKey: "children") as? NSOrderedSet {
            for case let childObject as NSManagedObject in childrenSet {
                if let child = try? convertToLevel4(childObject, context: context) {
                    children.append(child)
                }
            }
        }

        return ComplexModelLevel3(id: id, label: label, amount: amount, children: children)
    }

    private nonisolated func convertToLevel4(_ object: NSManagedObject, context: NSManagedObjectContext) throws -> ComplexModelLevel4 {
        guard
            let id = object.value(forKey: "id") as? String,
            let description = object.value(forKey: "descriptionText") as? String,
            let quantity = object.value(forKey: "quantity") as? Int
        else {
            throw DatabaseError.invalidData
        }

        var children: [ComplexModelLevel5] = []
        if let childrenSet = object.value(forKey: "children") as? NSOrderedSet {
            for case let childObject as NSManagedObject in childrenSet {
                if let child = try? convertToLevel5(childObject) {
                    children.append(child)
                }
            }
        }

        return ComplexModelLevel4(id: id, description: description, quantity: quantity, children: children)
    }

    private nonisolated func convertToLevel5(_ object: NSManagedObject) throws -> ComplexModelLevel5 {
        guard
            let id = object.value(forKey: "id") as? String,
            let note = object.value(forKey: "note") as? String,
            let index = object.value(forKey: "index") as? Int
        else {
            throw DatabaseError.invalidData
        }

        return ComplexModelLevel5(id: id, note: note, index: index)
    }

    private nonisolated func search(field: String, value: Any) async throws -> [Model] {
        guard let context = context else { throw DatabaseError.notFound }

        let request = NSFetchRequest<NSManagedObject>(entityName: "ComplexModelCD")

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
        return results.compactMap { try? convertToModel($0, context: context) }
    }
}
