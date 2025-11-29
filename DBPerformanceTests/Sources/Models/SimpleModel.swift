import Foundation

/// 단순 테스트 모델: 5개 기본 타입 속성
struct SimpleModel: DatabaseModel {
    let id: String
    var name: String
    var age: Int
    var score: Double
    var isActive: Bool
    var createdAt: Date

    nonisolated init(
        id: String = UUID().uuidString,
        name: String,
        age: Int,
        score: Double,
        isActive: Bool,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.age = age
        self.score = score
        self.isActive = isActive
        self.createdAt = createdAt
    }
}
