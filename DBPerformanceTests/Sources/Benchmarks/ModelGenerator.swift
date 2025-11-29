import Foundation

/// 벤치마크용 모델 데이터 생성 프로토콜
protocol ModelGenerator {
    associatedtype Model: DatabaseModel

    static func generate(id: String, index: Int) -> Model
    static func generateBatch(prefix: String, count: Int, startIndex: Int) -> [Model]
    static func generateConcurrent(prefix: String, index: Int) -> Model
    static func getUpdateFields() -> [String: Any]
}

// MARK: - SimpleModel Generator

struct SimpleModelGenerator: ModelGenerator {
    typealias Model = SimpleModel

    static func generate(id: String, index: Int) -> SimpleModel {
        SimpleModel(
            id: id,
            name: "Name \(index)",
            age: 20 + (index % 60),
            score: Double(index % 100),
            isActive: index % 2 == 0,
            createdAt: Date()
        )
    }

    static func generateBatch(prefix: String, count: Int, startIndex: Int) -> [SimpleModel] {
        (0..<count).map { index in
            SimpleModel(
                id: "\(prefix)-\(index)",
                name: "Batch \(index)",
                age: 25,
                score: 75.0,
                isActive: true
            )
        }
    }

    static func generateConcurrent(prefix: String, index: Int) -> SimpleModel {
        SimpleModel(
            id: "\(prefix)-\(index)",
            name: "Concurrent",
            age: 25,
            score: 50.0,
            isActive: true
        )
    }

    static func getUpdateFields() -> [String: Any] {
        ["age": 35]
    }
}

// MARK: - ComplexModel Generator

struct ComplexModelGenerator: ModelGenerator {
    typealias Model = ComplexModel

    static func generate(id: String, index: Int) -> ComplexModel {
        ComplexModel(
            id: id,
            name: "ComplexName \(index)",
            value: index,
            score: Double(index % 100),
            isEnabled: index % 2 == 0,
            timestamp: Date(),
            children: generateLevel2Children(count: min(3, index % 5 + 1), parentIndex: index)
        )
    }

    static func generateBatch(prefix: String, count: Int, startIndex: Int) -> [ComplexModel] {
        (0..<count).map { index in
            ComplexModel(
                id: "\(prefix)-\(index)",
                name: "BatchComplex \(index)",
                value: 1000 + index,
                score: 75.0,
                isEnabled: true,
                timestamp: Date(),
                children: generateLevel2Children(count: 2, parentIndex: index)
            )
        }
    }

    static func generateConcurrent(prefix: String, index: Int) -> ComplexModel {
        ComplexModel(
            id: "\(prefix)-\(index)",
            name: "ConcurrentComplex",
            value: 500 + index,
            score: 50.0,
            isEnabled: true,
            timestamp: Date(),
            children: generateLevel2Children(count: 1, parentIndex: index)
        )
    }

    static func getUpdateFields() -> [String: Any] {
        ["value": 999]
    }

    // MARK: - Helper methods for nested children

    private static func generateLevel2Children(count: Int, parentIndex: Int) -> [ComplexModelLevel2] {
        (0..<count).map { index in
            ComplexModelLevel2(
                id: UUID().uuidString,
                title: "Level2-\(parentIndex)-\(index)",
                count: index * 10,
                children: generateLevel3Children(count: min(2, index + 1), parentIndex: index)
            )
        }
    }

    private static func generateLevel3Children(count: Int, parentIndex: Int) -> [ComplexModelLevel3] {
        (0..<count).map { index in
            ComplexModelLevel3(
                id: UUID().uuidString,
                label: "Level3-\(parentIndex)-\(index)",
                amount: Double(index) * 100.5,
                children: generateLevel4Children(count: min(2, index + 1), parentIndex: index)
            )
        }
    }

    private static func generateLevel4Children(count: Int, parentIndex: Int) -> [ComplexModelLevel4] {
        (0..<count).map { index in
            ComplexModelLevel4(
                id: UUID().uuidString,
                description: "Level4-\(parentIndex)-\(index)",
                quantity: index + 1,
                children: generateLevel5Children(count: min(2, index + 1), parentIndex: index)
            )
        }
    }

    private static func generateLevel5Children(count: Int, parentIndex: Int) -> [ComplexModelLevel5] {
        (0..<count).map { index in
            ComplexModelLevel5(
                id: UUID().uuidString,
                note: "Level5-\(parentIndex)-\(index)",
                index: index
            )
        }
    }
}
