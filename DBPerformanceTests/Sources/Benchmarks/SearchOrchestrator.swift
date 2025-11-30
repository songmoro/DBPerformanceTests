//
//  SearchOrchestrator.swift
//  DBPerformanceTests
//
//  검색 테스트 전체 조율 및 결과 저장
//  [TM-33] 검색 벤치마크 실행 절차
//

import Foundation

/// 검색 벤치마크 조율기
@MainActor
final class SearchOrchestrator {
    private let scenarios = SearchScenarios()

    // MARK: - Public API

    /// Realm 검색 벤치마크 실행
    /// - Parameter fixturePath: Fixture 파일 경로 (사용 안 함, 기존 DB 사용)
    /// - Parameter dataSize: 데이터 크기 ("100k" 또는 "1m")
    /// - Returns: 검색 벤치마크 전체 결과
    func runRealmBenchmark(fixturePath: String, dataSize: String = "100k") async throws -> SearchBenchmarkReport {
        // Fixtures 디렉토리의 사전 생성된 DB 사용
        let fixturesDir = getFixturesDirectory()
        let dbPath = "\(fixturesDir)/realm_\(dataSize).realm"

        guard FileManager.default.fileExists(atPath: dbPath) else {
            throw SearchOrchestratorError.dbFileNotFound(path: dbPath)
        }

        let searcher = RealmSearcher(dbPath: dbPath)

        do {
            // 1. 기존 DB 열기
            try searcher.initializeDB()

            // 2. 환경 정보 수집
            let environment = EnvironmentCollector.collect()

            // 3. 검색 시나리오 실행 (순수 검색 성능만 측정)
            let searchResults = try await scenarios.runRealm(searcher: searcher, indexed: true)

            // 4. 결과 조합
            let report = SearchBenchmarkReport(
                metadata: SearchBenchmarkReport.Metadata(
                    timestamp: Date(),
                    databaseName: "Realm",
                    databaseVersion: getRealmVersion(),
                    environment: environment
                ),
                fixtureLoadTimeMs: 0.0, // 사전 로드됨
                searchResults: searchResults
            )

            // 5. DB 파일 유지 (삭제 안 함)
            // No cleanup, no delete

            return report

        } catch {
            throw error
        }
    }

    /// CoreData 검색 벤치마크 실행
    /// - Parameter fixturePath: Fixture 파일 경로 (사용 안 함, 기존 DB 사용)
    /// - Parameter dataSize: 데이터 크기 ("100k" 또는 "1m")
    /// - Returns: 검색 벤치마크 전체 결과
    func runCoreDataBenchmark(fixturePath: String, dataSize: String = "100k") async throws -> SearchBenchmarkReport {
        let dbName = "CoreDataFixture_\(dataSize)"
        let searcher = CoreDataSearcher(dbName: dbName)

        do {
            // 1. 기존 DB 열기
            try searcher.initializeDB()

            // 2. 환경 정보 수집
            let environment = EnvironmentCollector.collect()

            // 3. 검색 시나리오 실행
            let searchResults = try await scenarios.runCoreData(searcher: searcher, indexed: true)

            // 4. 결과 조합
            let report = SearchBenchmarkReport(
                metadata: SearchBenchmarkReport.Metadata(
                    timestamp: Date(),
                    databaseName: "CoreData",
                    databaseVersion: getCoreDataVersion(),
                    environment: environment
                ),
                fixtureLoadTimeMs: 0.0, // 사전 로드됨
                searchResults: searchResults
            )

            // 5. DB 파일 유지
            // No cleanup, no delete

            return report

        } catch {
            throw error
        }
    }

    /// SwiftData 검색 벤치마크 실행
    /// - Parameter fixturePath: Fixture 파일 경로 (사용 안 함, 기존 DB 사용)
    /// - Parameter dataSize: 데이터 크기 ("100k" 또는 "1m")
    /// - Returns: 검색 벤치마크 전체 결과
    func runSwiftDataBenchmark(fixturePath: String, dataSize: String = "100k") async throws -> SearchBenchmarkReport {
        let searcher = SwiftDataSearcher()

        do {
            // 1. 기존 DB 열기
            try searcher.initializeDB()

            // 2. 환경 정보 수집
            let environment = EnvironmentCollector.collect()

            // 3. 검색 시나리오 실행
            let searchResults = try await scenarios.runSwiftData(searcher: searcher, indexed: true)

            // 4. 결과 조합
            let report = SearchBenchmarkReport(
                metadata: SearchBenchmarkReport.Metadata(
                    timestamp: Date(),
                    databaseName: "SwiftData",
                    databaseVersion: getSwiftDataVersion(),
                    environment: environment
                ),
                fixtureLoadTimeMs: 0.0, // 사전 로드됨
                searchResults: searchResults
            )

            // 5. DB 파일 유지
            // No cleanup, no delete

            return report

        } catch {
            throw error
        }
    }

    /// UserDefaults 검색 벤치마크 실행
    /// - Parameter fixturePath: Fixture 파일 경로 (사용 안 함, 기존 데이터 사용)
    /// - Parameter dataSize: 데이터 크기 ("100k"만 지원)
    /// - Returns: 검색 벤치마크 전체 결과
    func runUserDefaultsBenchmark(fixturePath: String, dataSize: String = "100k") async throws -> SearchBenchmarkReport {
        let searcher = UserDefaultsSearcher(suiteName: "com.dbperformance.fixture_\(dataSize)")

        do {
            // 1. 기존 데이터 사용
            try searcher.initializeDB()

            // 2. 환경 정보 수집
            let environment = EnvironmentCollector.collect()

            // 3. 검색 시나리오 실행 (UserDefaults는 인덱스 미지원)
            let searchResults = try await scenarios.runUserDefaults(searcher: searcher, indexed: false)

            // 4. 결과 조합
            let report = SearchBenchmarkReport(
                metadata: SearchBenchmarkReport.Metadata(
                    timestamp: Date(),
                    databaseName: "UserDefaults",
                    databaseVersion: "System",
                    environment: environment
                ),
                fixtureLoadTimeMs: 0.0, // 사전 로드됨
                searchResults: searchResults
            )

            // 5. 데이터 유지
            // No cleanup

            return report

        } catch {
            throw error
        }
    }

    /// Realm 관계형 검색 벤치마크 실행
    /// - Parameter fixturePath: Fixture 파일 경로
    /// - Parameter dataSize: 데이터 크기 ("100k" 또는 "1m")
    /// - Returns: 검색 벤치마크 전체 결과
    func runRealmRelationalBenchmark(fixturePath: String, dataSize: String = "100k") async throws -> SearchBenchmarkReport {
        let fixturesDir = getFixturesDirectory()
        let dbPath = "\(fixturesDir)/realm_relational_\(dataSize).realm"

        guard FileManager.default.fileExists(atPath: dbPath) else {
            throw SearchOrchestratorError.dbFileNotFound(path: dbPath)
        }

        let searcher = RealmRelationalSearcher(dbPath: dbPath)

        do {
            try searcher.initializeDB()
            let environment = EnvironmentCollector.collect()
            let searchResults = try await scenarios.runRealmRelational(searcher: searcher, indexed: true)

            let report = SearchBenchmarkReport(
                metadata: SearchBenchmarkReport.Metadata(
                    timestamp: Date(),
                    databaseName: "Realm-Relational",
                    databaseVersion: getRealmVersion(),
                    environment: environment
                ),
                fixtureLoadTimeMs: 0.0,
                searchResults: searchResults
            )

            return report

        } catch {
            throw error
        }
    }

    /// CoreData 관계형 검색 벤치마크 실행
    /// - Parameter fixturePath: Fixture 파일 경로
    /// - Parameter dataSize: 데이터 크기 ("100k" 또는 "1m")
    /// - Returns: 검색 벤치마크 전체 결과
    func runCoreDataRelationalBenchmark(fixturePath: String, dataSize: String = "100k") async throws -> SearchBenchmarkReport {
        let dbName = "CoreDataRelationalFixture_\(dataSize)"
        let searcher = CoreDataRelationalSearcher(dbName: dbName)

        do {
            try searcher.initializeDB()
            let environment = EnvironmentCollector.collect()
            let searchResults = try await scenarios.runCoreDataRelational(searcher: searcher, indexed: true)

            let report = SearchBenchmarkReport(
                metadata: SearchBenchmarkReport.Metadata(
                    timestamp: Date(),
                    databaseName: "CoreData-Relational",
                    databaseVersion: getCoreDataVersion(),
                    environment: environment
                ),
                fixtureLoadTimeMs: 0.0,
                searchResults: searchResults
            )

            return report

        } catch {
            throw error
        }
    }

    /// SwiftData 관계형 검색 벤치마크 실행
    /// - Parameter fixturePath: Fixture 파일 경로
    /// - Parameter dataSize: 데이터 크기 ("100k" 또는 "1m")
    /// - Returns: 검색 벤치마크 전체 결과
    func runSwiftDataRelationalBenchmark(fixturePath: String, dataSize: String = "100k") async throws -> SearchBenchmarkReport {
        let searcher = SwiftDataRelationalSearcher()

        do {
            try searcher.initializeDB()
            let environment = EnvironmentCollector.collect()
            let searchResults = try await scenarios.runSwiftDataRelational(searcher: searcher, indexed: true)

            let report = SearchBenchmarkReport(
                metadata: SearchBenchmarkReport.Metadata(
                    timestamp: Date(),
                    databaseName: "SwiftData-Relational",
                    databaseVersion: getSwiftDataVersion(),
                    environment: environment
                ),
                fixtureLoadTimeMs: 0.0,
                searchResults: searchResults
            )

            return report

        } catch {
            throw error
        }
    }

    /// 모든 DB에 대해 검색 벤치마크 실행
    /// - Parameter fixturePath: Fixture 파일 경로
    /// - Parameter dataSize: 데이터 크기 ("100k" 또는 "1m")
    /// - Returns: 각 DB별 검색 벤치마크 결과 배열
    func runAllBenchmarks(fixturePath: String, dataSize: String = "100k") async throws -> [SearchBenchmarkReport] {
        var reports: [SearchBenchmarkReport] = []

        // Realm
        let realmReport = try await runRealmBenchmark(fixturePath: fixturePath, dataSize: dataSize)
        reports.append(realmReport)

        // CoreData
        let coreDataReport = try await runCoreDataBenchmark(fixturePath: fixturePath, dataSize: dataSize)
        reports.append(coreDataReport)

        // SwiftData
        let swiftDataReport = try await runSwiftDataBenchmark(fixturePath: fixturePath, dataSize: dataSize)
        reports.append(swiftDataReport)

        // UserDefaults (100k만 지원)
        if dataSize == "100k" {
            let userDefaultsReport = try await runUserDefaultsBenchmark(fixturePath: fixturePath, dataSize: dataSize)
            reports.append(userDefaultsReport)
        }

        return reports
    }

    /// 결과를 JSON 파일로 저장
    /// - Parameters:
    ///   - reports: 검색 벤치마크 결과 배열
    ///   - directory: 저장할 디렉토리 경로
    func saveReports(_ reports: [SearchBenchmarkReport], to directory: URL) throws {
        // 디렉토리 생성
        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        // 각 리포트를 개별 파일로 저장
        for report in reports {
            try report.save(to: directory)
        }

        // 전체 비교 리포트 생성
        let comparisonReport = createComparisonReport(reports)
        try comparisonReport.save(to: directory, filename: "comparison.json")
    }

    // MARK: - Private Helpers

    /// Fixtures 디렉토리 경로 반환
    private func getFixturesDirectory() -> String {
        let projectDir = FileManager.default.currentDirectoryPath
        return "\(projectDir)/Sources/Fixtures"
    }

    /// 비교 리포트 생성
    private func createComparisonReport(_ reports: [SearchBenchmarkReport]) -> SearchComparisonReport {
        var scenarioComparisons: [String: [SearchComparisonReport.DatabasePerformance]] = [:]

        // 시나리오별로 각 DB 성능 수집
        for report in reports {
            for result in report.searchResults {
                if scenarioComparisons[result.scenario] == nil {
                    scenarioComparisons[result.scenario] = []
                }

                scenarioComparisons[result.scenario]?.append(
                    SearchComparisonReport.DatabasePerformance(
                        databaseName: report.metadata.databaseName,
                        responseTimeMs: result.responseTimeMs,
                        resultCount: result.resultCount
                    )
                )
            }
        }

        return SearchComparisonReport(
            timestamp: Date(),
            scenarioComparisons: scenarioComparisons
        )
    }

    /// Realm 버전 가져오기
    private func getRealmVersion() -> String {
        // RealmSwift 프레임워크 버전 (실제 구현 시 수정 필요)
        return "10.45.0"
    }

    /// CoreData 버전 가져오기
    private func getCoreDataVersion() -> String {
        // macOS 시스템 버전과 연동
        return "System"
    }

    /// SwiftData 버전 가져오기
    private func getSwiftDataVersion() -> String {
        // macOS 시스템 버전과 연동
        return "System"
    }
}

// MARK: - Search Benchmark Report

/// 검색 벤치마크 전체 결과
struct SearchBenchmarkReport: Codable, Sendable {
    let metadata: Metadata
    let fixtureLoadTimeMs: Double
    let searchResults: [SearchBenchmarkResult]

    struct Metadata: Codable, Sendable {
        let timestamp: Date
        let databaseName: String
        let databaseVersion: String
        let environment: BenchmarkResult.EnvironmentInfo
    }

    /// JSON 파일로 저장
    func save(to directory: URL) throws {
        let formatter = ISO8601DateFormatter()
        let timestamp = formatter.string(from: metadata.timestamp)
        let filename = "\(timestamp)-\(metadata.databaseName)-search.json"
        let fileURL = directory.appendingPathComponent(filename)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(self)
        try data.write(to: fileURL)
    }
}

// MARK: - Errors

enum SearchOrchestratorError: Error, CustomStringConvertible {
    case dbFileNotFound(path: String)

    var description: String {
        switch self {
        case .dbFileNotFound(let path):
            return "DB file not found: \(path). Please generate fixtures first."
        }
    }
}

// MARK: - Comparison Report

/// DB 간 검색 성능 비교 리포트
struct SearchComparisonReport: Codable, Sendable {
    let timestamp: Date
    let scenarioComparisons: [String: [DatabasePerformance]]

    struct DatabasePerformance: Codable, Sendable {
        let databaseName: String
        let responseTimeMs: Double
        let resultCount: Int
    }

    /// JSON 파일로 저장
    func save(to directory: URL, filename: String) throws {
        let fileURL = directory.appendingPathComponent(filename)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(self)
        try data.write(to: fileURL)
    }
}
