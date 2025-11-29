import Foundation

/// 모든 테스트 데이터 모델이 준수해야 하는 프로토콜
protocol DatabaseModel: Sendable, Codable, Hashable {
    var id: String { get }
}
