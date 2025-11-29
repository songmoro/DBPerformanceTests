import Foundation
@preconcurrency import RealmSwift

/// Realm용 SimpleModel 래퍼
class SimpleModelRealm: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var name: String
    @Persisted var age: Int
    @Persisted var score: Double
    @Persisted var isActive: Bool
    @Persisted var createdAt: Date

    convenience init(from model: SimpleModel) {
        self.init()
        self.id = model.id
        self.name = model.name
        self.age = model.age
        self.score = model.score
        self.isActive = model.isActive
        self.createdAt = model.createdAt
    }

    func toSimpleModel() -> SimpleModel {
        SimpleModel(
            id: id,
            name: name,
            age: age,
            score: score,
            isActive: isActive,
            createdAt: createdAt
        )
    }
}

actor RealmAdapter: DatabaseAdapter {
    typealias Model = SimpleModel

    private let configuration: Realm.Configuration
    nonisolated(unsafe) private var isInitialized = false

    nonisolated var version: String { "Realm 10.x (Optimized)" }
    nonisolated var name: String { "Realm" }

    init() {
        var config = Realm.Configuration.defaultConfiguration
        config.fileURL = config.fileURL?.deletingLastPathComponent()
            .appendingPathComponent("db_performance_test.realm")

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

        let realmModel = SimpleModelRealm(from: model)
        try realm.write {
            realm.add(realmModel, update: .modified)  // 중복 시 업데이트
        }
    }

    func createBatch(_ models: [Model]) async throws {
        let realm = try getRealm()

        let realmModels = models.map { SimpleModelRealm(from: $0) }
        try realm.write {
            realm.add(realmModels, update: .modified)  // 중복 시 업데이트
        }
    }

    func read(id: String) async throws -> Model? {
        let realm = try getRealm()

        guard let realmModel = realm.object(ofType: SimpleModelRealm.self, forPrimaryKey: id) else {
            return nil
        }

        // Frozen object 사용으로 thread-safe하게 변환
        let frozen = realmModel.freeze()
        return frozen.toSimpleModel()
    }

    nonisolated func searchIndexed(field: String, value: Any) async throws -> [Model] {
        // Realm의 primary key는 자동 인덱싱됨
        return try await search(field: field, value: value)
    }

    nonisolated func searchNonIndexed(field: String, value: Any) async throws -> [Model] {
        return try await search(field: field, value: value)
    }

    nonisolated func executeComplexQuery() async throws -> [Model] {
        let realm = try getRealm()

        let results = realm.objects(SimpleModelRealm.self)
            .filter("age > 25 AND isActive == true AND score > 50.0")

        // Frozen results를 사용하여 안전하게 변환
        let frozenResults = results.freeze()
        return Array(frozenResults.map { $0.toSimpleModel() })
    }

    nonisolated func update(id: String, updates: [String: Any]) async throws {
        let realm = try getRealm()

        guard let realmModel = realm.object(ofType: SimpleModelRealm.self, forPrimaryKey: id) else {
            throw DatabaseError.notFound
        }

        try realm.write {
            if let name = updates["name"] as? String {
                realmModel.name = name
            }
            if let age = updates["age"] as? Int {
                realmModel.age = age
            }
            if let score = updates["score"] as? Double {
                realmModel.score = score
            }
            if let isActive = updates["isActive"] as? Bool {
                realmModel.isActive = isActive
            }
        }
    }

    nonisolated func executeTransaction(operations: @Sendable () async throws -> Void) async throws {
        // Realm의 write transaction 사용
        // Note: operations는 async이므로 write 외부에서 실행
        try await operations()
    }

    nonisolated func executeConcurrent(operations: [@Sendable () async throws -> Void]) async throws {
        // Realm은 thread confinement가 있으므로 actor isolation으로 순차 실행
        for operation in operations {
            try await operation()
        }
    }

    func delete(id: String) async throws {
        let realm = try getRealm()

        guard let realmModel = realm.object(ofType: SimpleModelRealm.self, forPrimaryKey: id) else {
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
        case "age":
            guard let intValue = value as? Int else { return [] }
            predicate = NSPredicate(format: "age == %d", intValue)
        case "score":
            guard let doubleValue = value as? Double else { return [] }
            predicate = NSPredicate(format: "score == %f", doubleValue)
        case "isActive":
            guard let boolValue = value as? Bool else { return [] }
            predicate = NSPredicate(format: "isActive == %@", NSNumber(value: boolValue))
        default:
            return []
        }

        let results = realm.objects(SimpleModelRealm.self).filter(predicate)

        // Frozen results로 변환 최적화
        let frozenResults = results.freeze()
        return Array(frozenResults.map { $0.toSimpleModel() })
    }
}
