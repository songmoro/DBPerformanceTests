//
//  FixtureGenerationConfig.swift
//  DBPerformanceTests
//
//  Fixture 생성 설정
//  [CR-74] Fixture 생성은 FixtureGenerationConfig enum 사용
//

import Foundation

/// Configuration for fixture generation
/// Fixture 생성을 위한 enum 기반 설정으로 일관성 보장
///
/// **사용 예시:**
/// ```swift
/// await FixtureGenerationConfig.flat100k.generate()
/// await FixtureGenerationConfig.relational1m.generate()
/// ```
enum FixtureGenerationConfig: CustomStringConvertible, CaseIterable {

    /// Flat model, 100K records
    case flat100k

    /// Flat model, 1M records
    case flat1m

    /// Relational model (ProductRecord + Tags), 100K records
    case relational100k

    /// Relational model (ProductRecord + Tags), 1M records
    case relational1m

    // MARK: - Configuration Properties

    /// Total record count to generate
    /// 생성할 레코드 수
    var recordCount: Int {
        switch self {
        case .flat100k, .relational100k:
            return 100_000
        case .flat1m, .relational1m:
            return 1_000_000
        }
    }

    /// File suffix for naming
    /// 파일명에 사용될 접미사
    var fileSuffix: String {
        switch self {
        case .flat100k, .relational100k:
            return "100k"
        case .flat1m, .relational1m:
            return "1m"
        }
    }

    /// Whether this is a relational model
    /// Relational 모델 여부
    var isRelational: Bool {
        switch self {
        case .flat100k, .flat1m:
            return false
        case .relational100k, .relational1m:
            return true
        }
    }

    /// JSON file name
    /// 생성될 JSON 파일명
    var fileName: String {
        let prefix = isRelational ? "relational" : "flat"
        return "\(prefix)-\(fileSuffix).json"
    }

    /// ID prefix for records
    /// 레코드 ID에 사용될 접두사
    var idPrefix: String {
        isRelational ? "PROD" : "FLAT"
    }

    /// Whether UserDefaults generation should be included
    /// UserDefaults DB 생성 여부 (100k만 지원)
    var includesUserDefaults: Bool {
        recordCount <= 100_000
    }

    // MARK: - File Paths

    /// Get full file path for JSON fixture
    /// - Parameter baseDir: 프로젝트 기본 디렉토리
    /// - Returns: JSON fixture 파일 전체 경로
    func jsonFilePath(baseDir: String) -> String {
        "\(baseDir)/Sources/Fixtures/\(fileName)"
    }

    /// Get Realm DB file path
    /// - Parameter fixturesPath: Fixtures 디렉토리 경로
    /// - Returns: Realm DB 파일 경로
    func realmDBPath(fixturesPath: String) -> String {
        "\(fixturesPath)/realm_\(fileSuffix).realm"
    }

    /// Get CoreData DB file path
    /// - Parameter fixturesPath: Fixtures 디렉토리 경로
    /// - Returns: CoreData SQLite 파일 경로
    func coreDataDBPath(fixturesPath: String) -> String {
        "\(fixturesPath)/coredata_\(fileSuffix).sqlite"
    }

    /// Get SwiftData DB file path
    /// - Parameter fixturesPath: Fixtures 디렉토리 경로
    /// - Returns: SwiftData SQLite 파일 경로
    func swiftDataDBPath(fixturesPath: String) -> String {
        "\(fixturesPath)/swiftdata_\(fileSuffix).sqlite"
    }

    /// Get UserDefaults suite name
    /// - Returns: UserDefaults suite 이름
    func userDefaultsSuiteName() -> String {
        "fixture_\(fileSuffix)"
    }

    // MARK: - Description

    /// Human-readable description
    var description: String {
        let type = isRelational ? "Relational" : "Flat"
        let count = recordCount >= 1_000_000 ? "1M" : "100K"
        return "\(type) \(count) Records"
    }

    /// Detailed description with file info
    var detailedDescription: String {
        """
        \(description)
        - JSON File: \(fileName)
        - ID Prefix: \(idPrefix)
        - Record Count: \(formatNumber(recordCount))
        - Includes UserDefaults: \(includesUserDefaults ? "Yes" : "No")
        """
    }

    // MARK: - Helper Methods

    /// Format number with thousand separators
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    // MARK: - Scenario Groups

    /// All flat model configurations
    static var flatConfigs: [FixtureGenerationConfig] {
        [.flat100k, .flat1m]
    }

    /// All relational model configurations
    static var relationalConfigs: [FixtureGenerationConfig] {
        [.relational100k, .relational1m]
    }

    /// All 100K configurations
    static var hundredKConfigs: [FixtureGenerationConfig] {
        [.flat100k, .relational100k]
    }

    /// All 1M configurations
    static var oneMillionConfigs: [FixtureGenerationConfig] {
        [.flat1m, .relational1m]
    }
}
