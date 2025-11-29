import Foundation
import SwiftData

@Model
final class ComplexModelSD {
    @Attribute(.unique) var id: String
    var name: String
    var value: Int
    var score: Double
    var isEnabled: Bool
    var timestamp: Date

    @Relationship(deleteRule: .cascade) var children: [ComplexModelLevel2SD]

    init(id: String, name: String, value: Int, score: Double, isEnabled: Bool, timestamp: Date, children: [ComplexModelLevel2SD]) {
        self.id = id
        self.name = name
        self.value = value
        self.score = score
        self.isEnabled = isEnabled
        self.timestamp = timestamp
        self.children = children
    }

    convenience init(from model: ComplexModel) {
        let children = model.children.map { ComplexModelLevel2SD(from: $0) }
        self.init(
            id: model.id,
            name: model.name,
            value: model.value,
            score: model.score,
            isEnabled: model.isEnabled,
            timestamp: model.timestamp,
            children: children
        )
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

@Model
final class ComplexModelLevel2SD {
    var id: String
    var title: String
    var count: Int

    @Relationship(deleteRule: .cascade) var children: [ComplexModelLevel3SD]

    init(id: String, title: String, count: Int, children: [ComplexModelLevel3SD]) {
        self.id = id
        self.title = title
        self.count = count
        self.children = children
    }

    convenience init(from model: ComplexModelLevel2) {
        let children = model.children.map { ComplexModelLevel3SD(from: $0) }
        self.init(id: model.id, title: model.title, count: model.count, children: children)
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

@Model
final class ComplexModelLevel3SD {
    var id: String
    var label: String
    var amount: Double

    @Relationship(deleteRule: .cascade) var children: [ComplexModelLevel4SD]

    init(id: String, label: String, amount: Double, children: [ComplexModelLevel4SD]) {
        self.id = id
        self.label = label
        self.amount = amount
        self.children = children
    }

    convenience init(from model: ComplexModelLevel3) {
        let children = model.children.map { ComplexModelLevel4SD(from: $0) }
        self.init(id: model.id, label: model.label, amount: model.amount, children: children)
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

@Model
final class ComplexModelLevel4SD {
    var id: String
    var descriptionText: String
    var quantity: Int

    @Relationship(deleteRule: .cascade) var children: [ComplexModelLevel5SD]

    init(id: String, descriptionText: String, quantity: Int, children: [ComplexModelLevel5SD]) {
        self.id = id
        self.descriptionText = descriptionText
        self.quantity = quantity
        self.children = children
    }

    convenience init(from model: ComplexModelLevel4) {
        let children = model.children.map { ComplexModelLevel5SD(from: $0) }
        self.init(id: model.id, descriptionText: model.description, quantity: model.quantity, children: children)
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

@Model
final class ComplexModelLevel5SD {
    var id: String
    var note: String
    var index: Int

    init(id: String, note: String, index: Int) {
        self.id = id
        self.note = note
        self.index = index
    }

    convenience init(from model: ComplexModelLevel5) {
        self.init(id: model.id, note: model.note, index: model.index)
    }

    func toLevel5() -> ComplexModelLevel5 {
        ComplexModelLevel5(id: id, note: note, index: index)
    }
}

actor SwiftDataComplexAdapter: DatabaseAdapter {
    typealias Model = ComplexModel

    nonisolated(unsafe) private var modelContainer: ModelContainer?
    nonisolated(unsafe) private var modelContext: ModelContext?

    nonisolated var version: String { "SwiftData (macOS 15+)" }
    nonisolated var name: String { "SwiftData" }

    func initialize() async throws {
        let schema = Schema([
            ComplexModelSD.self,
            ComplexModelLevel2SD.self,
            ComplexModelLevel3SD.self,
            ComplexModelLevel4SD.self,
            ComplexModelLevel5SD.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer!)
    }

    func create(_ model: Model) async throws {
        guard let context = modelContext else { throw DatabaseError.notFound }

        let sdModel = ComplexModelSD(from: model)
        context.insert(sdModel)
        try context.save()
    }

    func createBatch(_ models: [Model]) async throws {
        guard let context = modelContext else { throw DatabaseError.notFound }

        for model in models {
            let sdModel = ComplexModelSD(from: model)
            context.insert(sdModel)
        }

        try context.save()
    }

    func read(id: String) async throws -> Model? {
        guard let context = modelContext else { throw DatabaseError.notFound }

        let predicate = #Predicate<ComplexModelSD> { $0.id == id }
        let descriptor = FetchDescriptor<ComplexModelSD>(predicate: predicate)

        let results = try context.fetch(descriptor)
        return results.first?.toComplexModel()
    }

    nonisolated func searchIndexed(field: String, value: Any) async throws -> [Model] {
        return try await search(field: field, value: value)
    }

    nonisolated func searchNonIndexed(field: String, value: Any) async throws -> [Model] {
        return try await search(field: field, value: value)
    }

    nonisolated func executeComplexQuery() async throws -> [Model] {
        guard let context = modelContext else { throw DatabaseError.notFound }

        let predicate = #Predicate<ComplexModelSD> { model in
            model.value > 500 && model.isEnabled && model.score > 50.0
        }
        let descriptor = FetchDescriptor<ComplexModelSD>(predicate: predicate)

        let results = try context.fetch(descriptor)
        return results.map { $0.toComplexModel() }
    }

    nonisolated func update(id: String, updates: [String: Any]) async throws {
        guard let context = modelContext else { throw DatabaseError.notFound }

        let predicate = #Predicate<ComplexModelSD> { $0.id == id }
        let descriptor = FetchDescriptor<ComplexModelSD>(predicate: predicate)

        guard let model = try context.fetch(descriptor).first else {
            throw DatabaseError.notFound
        }

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

        try context.save()
    }

    nonisolated func executeTransaction(operations: @Sendable () async throws -> Void) async throws {
        try await operations()
        guard let context = modelContext else { throw DatabaseError.notFound }
        try context.save()
    }

    nonisolated func executeConcurrent(operations: [@Sendable () async throws -> Void]) async throws {
        for operation in operations {
            try await operation()
        }
    }

    func delete(id: String) async throws {
        guard let context = modelContext else { throw DatabaseError.notFound }

        let predicate = #Predicate<ComplexModelSD> { $0.id == id }
        let descriptor = FetchDescriptor<ComplexModelSD>(predicate: predicate)

        guard let model = try context.fetch(descriptor).first else {
            throw DatabaseError.notFound
        }

        context.delete(model)
        try context.save()
    }

    func deleteAll() async throws {
        guard let context = modelContext else { throw DatabaseError.notFound }

        try context.delete(model: ComplexModelSD.self)
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

        let predicate: Predicate<ComplexModelSD>

        switch field {
        case "name":
            guard let stringValue = value as? String else { return [] }
            predicate = #Predicate { $0.name == stringValue }
        case "value":
            guard let intValue = value as? Int else { return [] }
            predicate = #Predicate { $0.value == intValue }
        case "score":
            guard let doubleValue = value as? Double else { return [] }
            predicate = #Predicate { $0.score == doubleValue }
        case "isEnabled":
            guard let boolValue = value as? Bool else { return [] }
            predicate = #Predicate { $0.isEnabled == boolValue }
        default:
            return []
        }

        let descriptor = FetchDescriptor<ComplexModelSD>(predicate: predicate)
        let results = try context.fetch(descriptor)
        return results.map { $0.toComplexModel() }
    }
}
