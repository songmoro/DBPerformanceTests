import Foundation

actor UserDefaultsComplexAdapter: DatabaseAdapter {
    typealias Model = ComplexModel

    private let userDefaults: UserDefaults
    private let key = "ComplexModels"

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
        return try await search(field: field, value: value)
    }

    nonisolated func searchNonIndexed(field: String, value: Any) async throws -> [Model] {
        return try await search(field: field, value: value)
    }

    nonisolated func executeComplexQuery() async throws -> [Model] {
        let models = try await readAll()
        // 예시: value > 500이고 isEnabled == true이고 score > 50.0
        return models.filter { $0.value > 500 && $0.isEnabled && $0.score > 50.0 }
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
        if let value = updates["value"] as? Int {
            model.value = value
        }
        if let score = updates["score"] as? Double {
            model.score = score
        }
        if let isEnabled = updates["isEnabled"] as? Bool {
            model.isEnabled = isEnabled
        }

        models[index] = model
        try await saveAll(models)
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
            case "value":
                return (value as? Int) == model.value
            case "score":
                return (value as? Double) == model.score
            case "isEnabled":
                return (value as? Bool) == model.isEnabled
            default:
                return false
            }
        }
    }
}
