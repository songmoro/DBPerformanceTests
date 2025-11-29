import Foundation

/// 복잡 테스트 모델: 관계 포함 (최대 5뎁스)
struct ComplexModel: DatabaseModel {
    let id: String
    var name: String
    var value: Int
    var score: Double
    var isEnabled: Bool
    var timestamp: Date

    // 1:N 관계 (depth 1)
    var children: [ComplexModelLevel2]

    nonisolated init(
        id: String = UUID().uuidString,
        name: String,
        value: Int,
        score: Double,
        isEnabled: Bool,
        timestamp: Date = Date(),
        children: [ComplexModelLevel2] = []
    ) {
        self.id = id
        self.name = name
        self.value = value
        self.score = score
        self.isEnabled = isEnabled
        self.timestamp = timestamp
        self.children = children
    }
}

// Depth 2
struct ComplexModelLevel2: Codable, Hashable, Identifiable, Sendable {
    let id: String
    var title: String
    var count: Int
    var children: [ComplexModelLevel3]

    init(
        id: String = UUID().uuidString,
        title: String,
        count: Int,
        children: [ComplexModelLevel3] = []
    ) {
        self.id = id
        self.title = title
        self.count = count
        self.children = children
    }
}

// Depth 3
struct ComplexModelLevel3: Codable, Hashable, Identifiable, Sendable {
    let id: String
    var label: String
    var amount: Double
    var children: [ComplexModelLevel4]

    init(
        id: String = UUID().uuidString,
        label: String,
        amount: Double,
        children: [ComplexModelLevel4] = []
    ) {
        self.id = id
        self.label = label
        self.amount = amount
        self.children = children
    }
}

// Depth 4
struct ComplexModelLevel4: Codable, Hashable, Identifiable, Sendable {
    let id: String
    var description: String
    var quantity: Int
    var children: [ComplexModelLevel5]

    init(
        id: String = UUID().uuidString,
        description: String,
        quantity: Int,
        children: [ComplexModelLevel5] = []
    ) {
        self.id = id
        self.description = description
        self.quantity = quantity
        self.children = children
    }
}

// Depth 5 (최대 깊이)
struct ComplexModelLevel5: Codable, Hashable, Identifiable, Sendable {
    let id: String
    var note: String
    var index: Int

    init(
        id: String = UUID().uuidString,
        note: String,
        index: Int
    ) {
        self.id = id
        self.note = note
        self.index = index
    }
}
