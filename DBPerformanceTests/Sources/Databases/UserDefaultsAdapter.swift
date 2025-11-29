import Foundation

actor UserDefaultsAdapter: DatabaseAdapter {
    typealias Model = SimpleModel

    private let userDefaults: UserDefaults
    private let key = "SimpleModels"

    nonisolated var version: String { "System" }
    nonisolated var name: String { "UserDefaults" }

    init(suiteName: String? = nil) {
        self.userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
    }

    func initialize() async throws {
        // UserDefaults는 별도 초기화 불필요
    }

    func create(_ model: Model) async throws {
        var models = try await readAll()
        models.append(model)
        try await saveAll(models)
    }

    func createBatch(_ models: [Model]) async throws {
        var existing = try await readAll()
        existing.append(contentsOf: models)
        try await saveAll(existing)
    }

    func read(id: String) async throws -> Model? {
        let models = try await readAll()
        return models.first { $0.id == id }
    }

    nonisolated func searchIndexed(field: String, value: Any) async throws -> [Model] {
        // UserDefaults는 인덱스 개념 없음, 전체 스캔
        return try await search(field: field, value: value)
    }

    nonisolated func searchNonIndexed(field: String, value: Any) async throws -> [Model] {
        return try await search(field: field, value: value)
    }

    nonisolated func executeComplexQuery() async throws -> [Model] {
        let models = try await readAll()
        // 예시: age > 25이고 isActive == true이고 score > 50.0
        return models.filter { $0.age > 25 && $0.isActive && $0.score > 50.0 }
    }

    nonisolated func update(id: String, updates: [String: Any]) async throws {
        var models = try await readAll()
        guard let index = models.firstIndex(where: { $0.id == id }) else {
            throw DatabaseError.notFound
        }

        var model = models[index]

        if let name = updates["name"] as? String {
            model.name = name
        }
        if let age = updates["age"] as? Int {
            model.age = age
        }
        if let score = updates["score"] as? Double {
            model.score = score
        }
        if let isActive = updates["isActive"] as? Bool {
            model.isActive = isActive
        }

        models[index] = model
        try await saveAll(models)
    }

    nonisolated func executeTransaction(operations: @Sendable () async throws -> Void) async throws {
        // UserDefaults는 트랜잭션 개념 없음, 단순 실행
        try await operations()
    }

    nonisolated func executeConcurrent(operations: [@Sendable () async throws -> Void]) async throws {
        // UserDefaults는 thread-safe하지 않으므로 순차 실행
        // actor isolation으로 인해 실제로는 순차적으로 실행됨
        for operation in operations {
            try await operation()
        }
    }

    func delete(id: String) async throws {
        var models = try await readAll()
        models.removeAll { $0.id == id }
        try await saveAll(models)
    }

    func deleteAll() async throws {
        userDefaults.removeObject(forKey: key)
    }

    func cleanup() async throws {
        try await deleteAll()
    }

    // MARK: - Private Helpers

    private func readAll() async throws -> [Model] {
        guard let data = userDefaults.data(forKey: key) else {
            return []
        }
        return try JSONDecoder().decode([Model].self, from: data)
    }

    private func saveAll(_ models: [Model]) async throws {
        let data = try JSONEncoder().encode(models)
        userDefaults.set(data, forKey: key)
    }

    private nonisolated func search(field: String, value: Any) async throws -> [Model] {
        let models = try await readAll()

        return models.filter { model in
            switch field {
            case "name":
                return (value as? String) == model.name
            case "age":
                return (value as? Int) == model.age
            case "score":
                return (value as? Double) == model.score
            case "isActive":
                return (value as? Bool) == model.isActive
            default:
                return false
            }
        }
    }
}

enum DatabaseError: Error {
    case notFound
    case invalidData
}
