import Foundation
import SwiftData

@Model
final class SimpleModelSD {
    @Attribute(.unique) var id: String
    var name: String
    var age: Int
    var score: Double
    var isActive: Bool
    var createdAt: Date

    init(id: String, name: String, age: Int, score: Double, isActive: Bool, createdAt: Date) {
        self.id = id
        self.name = name
        self.age = age
        self.score = score
        self.isActive = isActive
        self.createdAt = createdAt
    }

    func toSimpleModel() -> SimpleModel {
        SimpleModel(id: id, name: name, age: age, score: score, isActive: isActive, createdAt: createdAt)
    }
}

actor SwiftDataAdapter: DatabaseAdapter {
    typealias Model = SimpleModel

    nonisolated(unsafe) private var modelContainer: ModelContainer?
    nonisolated(unsafe) private var modelContext: ModelContext?

    nonisolated var version: String { "SwiftData (macOS 15+)" }
    nonisolated var name: String { "SwiftData" }

    func initialize() async throws {
        let schema = Schema([SimpleModelSD.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer!)
    }

    func create(_ model: Model) async throws {
        guard let context = modelContext else { throw DatabaseError.notFound }

        let sdModel = SimpleModelSD(
            id: model.id,
            name: model.name,
            age: model.age,
            score: model.score,
            isActive: model.isActive,
            createdAt: model.createdAt
        )

        context.insert(sdModel)
        try context.save()
    }

    func createBatch(_ models: [Model]) async throws {
        guard let context = modelContext else { throw DatabaseError.notFound }

        for model in models {
            let sdModel = SimpleModelSD(
                id: model.id,
                name: model.name,
                age: model.age,
                score: model.score,
                isActive: model.isActive,
                createdAt: model.createdAt
            )
            context.insert(sdModel)
        }

        try context.save()
    }

    func read(id: String) async throws -> Model? {
        guard let context = modelContext else { throw DatabaseError.notFound }

        let predicate = #Predicate<SimpleModelSD> { $0.id == id }
        let descriptor = FetchDescriptor<SimpleModelSD>(predicate: predicate)

        let results = try context.fetch(descriptor)
        return results.first?.toSimpleModel()
    }

    nonisolated func searchIndexed(field: String, value: Any) async throws -> [Model] {
        // SwiftData는 자동 인덱싱, @Attribute(.unique)가 인덱스 역할
        return try await search(field: field, value: value)
    }

    nonisolated func searchNonIndexed(field: String, value: Any) async throws -> [Model] {
        return try await search(field: field, value: value)
    }

    nonisolated func executeComplexQuery() async throws -> [Model] {
        guard let context = modelContext else { throw DatabaseError.notFound }

        let predicate = #Predicate<SimpleModelSD> { model in
            model.age > 25 && model.isActive && model.score > 50.0
        }
        let descriptor = FetchDescriptor<SimpleModelSD>(predicate: predicate)

        let results = try context.fetch(descriptor)
        return results.map { $0.toSimpleModel() }
    }

    nonisolated func update(id: String, updates: [String: Any]) async throws {
        guard let context = modelContext else { throw DatabaseError.notFound }

        let predicate = #Predicate<SimpleModelSD> { $0.id == id }
        let descriptor = FetchDescriptor<SimpleModelSD>(predicate: predicate)

        guard let model = try context.fetch(descriptor).first else {
            throw DatabaseError.notFound
        }

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

        try context.save()
    }

    nonisolated func executeTransaction(operations: @Sendable () async throws -> Void) async throws {
        // SwiftData는 ModelContext가 트랜잭션 역할
        try await operations()
        guard let context = modelContext else { throw DatabaseError.notFound }
        try context.save()
    }

    nonisolated func executeConcurrent(operations: [@Sendable () async throws -> Void]) async throws {
        // ModelContext는 thread-safe하지 않으므로 actor isolation으로 순차 실행
        for operation in operations {
            try await operation()
        }
    }

    func delete(id: String) async throws {
        guard let context = modelContext else { throw DatabaseError.notFound }

        let predicate = #Predicate<SimpleModelSD> { $0.id == id }
        let descriptor = FetchDescriptor<SimpleModelSD>(predicate: predicate)

        guard let model = try context.fetch(descriptor).first else {
            throw DatabaseError.notFound
        }

        context.delete(model)
        try context.save()
    }

    func deleteAll() async throws {
        guard let context = modelContext else { throw DatabaseError.notFound }

        try context.delete(model: SimpleModelSD.self)
        try context.save()
    }

    func cleanup() async throws {
        try await deleteAll()
        modelContext = nil
        modelContainer = nil
    }

    // MARK: - Private Helpers

    private nonisolated func search(field: String, value: Any) async throws -> [Model] {
        guard let context = modelContext else { throw DatabaseError.notFound }

        let predicate: Predicate<SimpleModelSD>

        switch field {
        case "name":
            guard let stringValue = value as? String else { return [] }
            predicate = #Predicate { $0.name == stringValue }
        case "age":
            guard let intValue = value as? Int else { return [] }
            predicate = #Predicate { $0.age == intValue }
        case "score":
            guard let doubleValue = value as? Double else { return [] }
            predicate = #Predicate { $0.score == doubleValue }
        case "isActive":
            guard let boolValue = value as? Bool else { return [] }
            predicate = #Predicate { $0.isActive == boolValue }
        default:
            return []
        }

        let descriptor = FetchDescriptor<SimpleModelSD>(predicate: predicate)
        let results = try context.fetch(descriptor)
        return results.map { $0.toSimpleModel() }
    }
}
