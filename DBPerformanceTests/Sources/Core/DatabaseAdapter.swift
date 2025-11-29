import Foundation

/// 모든 데이터베이스 구현체가 준수해야 하는 공통 인터페이스
protocol DatabaseAdapter: Sendable {
    associatedtype Model: DatabaseModel

    /// DB 초기화
    func initialize() async throws

    /// 단일 데이터 생성
    func create(_ model: Model) async throws

    /// 배치 데이터 생성
    func createBatch(_ models: [Model]) async throws

    /// ID 기준 단순 조회
    func read(id: String) async throws -> Model?

    /// 색인 필드 기준 검색
    nonisolated func searchIndexed(field: String, value: Any) async throws -> [Model]

    /// 비색인 필드 기준 검색
    nonisolated func searchNonIndexed(field: String, value: Any) async throws -> [Model]

    /// 복잡한 쿼리 수행
    nonisolated func executeComplexQuery() async throws -> [Model]

    /// 데이터 수정
    nonisolated func update(id: String, updates: [String: Any]) async throws

    /// 트랜잭션 내 복수 작업
    nonisolated func executeTransaction(operations: @Sendable () async throws -> Void) async throws

    /// 동시 작업 수행
    nonisolated func executeConcurrent(operations: [@Sendable () async throws -> Void]) async throws

    /// 데이터 삭제
    func delete(id: String) async throws

    /// 전체 데이터 삭제
    func deleteAll() async throws

    /// DB 정리 및 종료
    func cleanup() async throws

    /// DB 버전 정보
    nonisolated var version: String { get }

    /// DB 이름
    nonisolated var name: String { get }
}

/// 배치 처리를 지원하는 어댑터를 위한 프로토콜
protocol FlushableAdapter: DatabaseAdapter {
    /// 대기 중인 변경사항을 강제로 저장
    func flush() async throws
}
