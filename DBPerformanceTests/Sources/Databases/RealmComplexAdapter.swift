import Foundation
@preconcurrency import RealmSwift

/// Realm용 ComplexModel 래퍼 (Level 1)
class ComplexModelRealm: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var name: String
    @Persisted var value: Int
    @Persisted var score: Double
    @Persisted var isEnabled: Bool
    @Persisted var timestamp: Date
    @Persisted var children: List<ComplexModelLevel2Realm>

    convenience init(from model: ComplexModel) {
        self.init()
        self.id = model.id
        self.name = model.name
        self.value = model.value
        self.score = model.score
        self.isEnabled = model.isEnabled
        self.timestamp = model.timestamp

        for child in model.children {
            self.children.append(ComplexModelLevel2Realm(from: child))
        }
    }

    func toComplexModel() -> ComplexModel {
        ComplexModel(
            id: id,
            name: name,
            value: value,
            score: score,
            isEnabled: isEnabled,
            timestamp: timestamp,
            children: children.map { $0.toLevel2() }
        )
    }
}

// Level 2
class ComplexModelLevel2Realm: Object {
    @Persisted var id: String
    @Persisted var title: String
    @Persisted var count: Int
    @Persisted var children: List<ComplexModelLevel3Realm>

    convenience init(from model: ComplexModelLevel2) {
        self.init()
        self.id = model.id
        self.title = model.title
        self.count = model.count

        for child in model.children {
            self.children.append(ComplexModelLevel3Realm(from: child))
        }
    }

    func toLevel2() -> ComplexModelLevel2 {
        ComplexModelLevel2(
            id: id,
            title: title,
            count: count,
            children: children.map { $0.toLevel3() }
        )
    }
}

// Level 3
class ComplexModelLevel3Realm: Object {
    @Persisted var id: String
    @Persisted var label: String
    @Persisted var amount: Double
    @Persisted var children: List<ComplexModelLevel4Realm>

    convenience init(from model: ComplexModelLevel3) {
        self.init()
        self.id = model.id
        self.label = model.label
        self.amount = model.amount

        for child in model.children {
            self.children.append(ComplexModelLevel4Realm(from: child))
        }
    }

    func toLevel3() -> ComplexModelLevel3 {
        ComplexModelLevel3(
            id: id,
            label: label,
            amount: amount,
            children: children.map { $0.toLevel4() }
        )
    }
}

// Level 4
class ComplexModelLevel4Realm: Object {
    @Persisted var id: String
    @Persisted var descriptionText: String
    @Persisted var quantity: Int
    @Persisted var children: List<ComplexModelLevel5Realm>

    convenience init(from model: ComplexModelLevel4) {
        self.init()
        self.id = model.id
        self.descriptionText = model.description
        self.quantity = model.quantity

        for child in model.children {
            self.children.append(ComplexModelLevel5Realm(from: child))
        }
    }

    func toLevel4() -> ComplexModelLevel4 {
        ComplexModelLevel4(
            id: id,
            description: descriptionText,
            quantity: quantity,
            children: children.map { $0.toLevel5() }
        )
    }
}

// Level 5
class ComplexModelLevel5Realm: Object {
    @Persisted var id: String
    @Persisted var note: String
    @Persisted var index: Int

    convenience init(from model: ComplexModelLevel5) {
        self.init()
        self.id = model.id
        self.note = model.note
        self.index = model.index
    }

    func toLevel5() -> ComplexModelLevel5 {
        ComplexModelLevel5(
            id: id,
            note: note,
            index: index
        )
    }
}

actor RealmComplexAdapter: DatabaseAdapter {
    typealias Model = ComplexModel

    private let configuration: Realm.Configuration
    nonisolated(unsafe) private var isInitialized = false

    nonisolated var version: String { "Realm 10.x (Optimized)" }
    nonisolated var name: String { "Realm" }

    init() {
        var config = Realm.Configuration.defaultConfiguration
        config.fileURL = config.fileURL?.deletingLastPathComponent()
            .appendingPathComponent("db_performance_test_complex.realm")
        config.schemaVersion = 1

        // 성능 최적화 설정 (기본값 유지 - 벤치마크는 여러 트랜잭션 동시 실행)
        // config.maximumNumberOfActiveVersions는 설정하지 않음 (기본값 사용)

        self.configuration = config
    }

    private nonisolated func getRealm() throws -> Realm {
        guard isInitialized else {
            throw DatabaseError.notFound
        }
        return try Realm(configuration: configuration)
    }

    func initialize() async throws {
        _ = try await MainActor.run {
            try Realm(configuration: configuration)
        }
        isInitialized = true
    }

    func create(_ model: Model) async throws {
        let realm = try getRealm()

        let realmModel = ComplexModelRealm(from: model)
        try realm.write {
            realm.add(realmModel, update: .modified)  // 중복 시 업데이트
        }
    }

    func createBatch(_ models: [Model]) async throws {
        let realm = try getRealm()

        let realmModels = models.map { ComplexModelRealm(from: $0) }
        try realm.write {
            realm.add(realmModels, update: .modified)  // 중복 시 업데이트
        }
    }

    func read(id: String) async throws -> Model? {
        let realm = try getRealm()

        guard let realmModel = realm.object(ofType: ComplexModelRealm.self, forPrimaryKey: id) else {
            return nil
        }

        // Frozen object 사용
        let frozen = realmModel.freeze()
        return frozen.toComplexModel()
    }

    nonisolated func searchIndexed(field: String, value: Any) async throws -> [Model] {
        return try await search(field: field, value: value)
    }

    nonisolated func searchNonIndexed(field: String, value: Any) async throws -> [Model] {
        return try await search(field: field, value: value)
    }

    nonisolated func executeComplexQuery() async throws -> [Model] {
        let realm = try getRealm()

        let results = realm.objects(ComplexModelRealm.self)
            .filter("value > 500 AND isEnabled == true AND score > 50.0")

        // Frozen results 사용
        let frozenResults = results.freeze()
        return Array(frozenResults.map { $0.toComplexModel() })
    }

    nonisolated func update(id: String, updates: [String: Any]) async throws {
        let realm = try getRealm()

        guard let realmModel = realm.object(ofType: ComplexModelRealm.self, forPrimaryKey: id) else {
            throw DatabaseError.notFound
        }

        try realm.write {
            if let name = updates["name"] as? String {
                realmModel.name = name
            }
            if let value = updates["value"] as? Int {
                realmModel.value = value
            }
            if let score = updates["score"] as? Double {
                realmModel.score = score
            }
            if let isEnabled = updates["isEnabled"] as? Bool {
                realmModel.isEnabled = isEnabled
            }
        }
    }

    nonisolated func executeTransaction(operations: @Sendable () async throws -> Void) async throws {
        try await operations()
    }

    nonisolated func executeConcurrent(operations: [@Sendable () async throws -> Void]) async throws {
        for operation in operations {
            try await operation()
        }
    }

    func delete(id: String) async throws {
        let realm = try getRealm()

        guard let realmModel = realm.object(ofType: ComplexModelRealm.self, forPrimaryKey: id) else {
            throw DatabaseError.notFound
        }

        try realm.write {
            realm.delete(realmModel)
        }
    }

    func deleteAll() async throws {
        let realm = try getRealm()

        try realm.write {
            realm.deleteAll()
        }
    }

    func cleanup() async throws {
        try await deleteAll()
        isInitialized = false
    }

    // MARK: - Private Helpers

    private nonisolated func search(field: String, value: Any) async throws -> [Model] {
        let realm = try getRealm()

        let predicate: NSPredicate

        switch field {
        case "name":
            guard let stringValue = value as? String else { return [] }
            predicate = NSPredicate(format: "name == %@", stringValue)
        case "value":
            guard let intValue = value as? Int else { return [] }
            predicate = NSPredicate(format: "value == %d", intValue)
        case "score":
            guard let doubleValue = value as? Double else { return [] }
            predicate = NSPredicate(format: "score == %f", doubleValue)
        case "isEnabled":
            guard let boolValue = value as? Bool else { return [] }
            predicate = NSPredicate(format: "isEnabled == %@", NSNumber(value: boolValue))
        default:
            return []
        }

        let results = realm.objects(ComplexModelRealm.self).filter(predicate)

        // Frozen results 사용
        let frozenResults = results.freeze()
        return Array(frozenResults.map { $0.toComplexModel() })
    }
}
