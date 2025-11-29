//
//  GenerateFixtures.swift
//  DBPerformanceTests
//
//  Fixture 생성 유틸리티
//  JSON + 4개 DB 파일 생성
//

import Foundation

/// Fixture 생성 실행 함수 (100K 데이터)
/// - JSON 파일 생성
/// - Realm, CoreData, SwiftData, UserDefaults DB 파일 생성
@MainActor
func generateFixtures() async {
    await generateFixturesWithCount(100_000, suffix: "100k")
}

/// Fixture 생성 실행 함수 (1M 데이터)
/// - JSON 파일 생성
/// - Realm, CoreData, SwiftData DB 파일 생성 (UserDefaults 제외)
@MainActor
func generateFixtures1M() async {
    await generateFixturesWithCount(1_000_000, suffix: "1m")
}

/// 공통 Fixture 생성 함수
/// - Parameter count: 생성할 데이터 개수
/// - Parameter suffix: 파일명 접미사 (100k, 1m 등)
@MainActor
private func generateFixturesWithCount(_ count: Int, suffix: String) async {
    let projectDir = FileManager.default.currentDirectoryPath
    let fixturesPath = "\(projectDir)/Sources/Fixtures"

    // Fixtures 디렉토리 확인/생성
    if !FileManager.default.fileExists(atPath: fixturesPath) {
        try? FileManager.default.createDirectory(
            atPath: fixturesPath,
            withIntermediateDirectories: true
        )
        print("Created directory: \(fixturesPath)")
    }

    let flatJsonPath = "\(fixturesPath)/flat-\(suffix).json"
    let countFormatted = String(format: "%,d", count)

    // Step 1: JSON Fixture 생성
    print("\n=== Step 1/5: Generating JSON Fixture (\(countFormatted) records) ===")
    print("Path: \(flatJsonPath)")
    if count >= 1_000_000 {
        print("This will take ~5-10 minutes...\n")
    } else {
        print("This will take ~30-60 seconds...\n")
    }

    var generator = FixtureGenerator(seed: 42)

    do {
        try generator.generateFlatFixture(to: flatJsonPath, count: count)
        print("✅ JSON fixture created\n")
    } catch {
        print("❌ ERROR: Failed to generate JSON fixture: \(error)")
        return
    }

    // Step 2: Realm DB 생성
    print("\n=== Step 2/5: Generating Realm DB ===")
    do {
        try await generateRealmDB(jsonPath: flatJsonPath, fixturesPath: fixturesPath, suffix: suffix)
        print("✅ Realm DB created\n")
    } catch {
        print("❌ ERROR: Failed to generate Realm DB: \(error)")
    }

    // Step 3: CoreData DB 생성
    print("\n=== Step 3/5: Generating CoreData DB ===")
    do {
        try await generateCoreDataDB(jsonPath: flatJsonPath, fixturesPath: fixturesPath, suffix: suffix)
        print("✅ CoreData DB created\n")
    } catch {
        print("❌ ERROR: Failed to generate CoreData DB: \(error)")
    }

    // Step 4: SwiftData DB 생성
    print("\n=== Step 4/5: Generating SwiftData DB ===")
    do {
        try await generateSwiftDataDB(jsonPath: flatJsonPath, fixturesPath: fixturesPath, suffix: suffix)
        print("✅ SwiftData DB created\n")
    } catch {
        print("❌ ERROR: Failed to generate SwiftData DB: \(error)")
    }

    // Step 5: UserDefaults 생성 (100k만 지원)
    if count <= 100_000 {
        print("\n=== Step 5/5: Generating UserDefaults ===")
        do {
            try await generateUserDefaultsDB(jsonPath: flatJsonPath, suffix: suffix)
            print("✅ UserDefaults created\n")
        } catch {
            print("❌ ERROR: Failed to generate UserDefaults: \(error)")
        }
    } else {
        print("\n=== Step 5/5: Skipping UserDefaults (not recommended for \(countFormatted) records) ===")
    }

    print("\n🎉 All fixtures generated successfully!")
    print("   JSON: \(flatJsonPath)")
    print("   Realm: \(fixturesPath)/realm_\(suffix).realm")
    print("   CoreData: \(fixturesPath)/coredata_\(suffix).sqlite")
    print("   SwiftData: \(fixturesPath)/swiftdata_\(suffix).sqlite")
    if count <= 100_000 {
        print("   UserDefaults: fixture_\(suffix) suite")
    }
}

// MARK: - DB Generation Functions

/// Realm DB 생성
@MainActor
private func generateRealmDB(jsonPath: String, fixturesPath: String, suffix: String) async throws {
    let dbPath = "\(fixturesPath)/realm_\(suffix).realm"
    let searcher = RealmSearcher(dbPath: dbPath)

    try searcher.initializeDB()
    let duration = try await searcher.loadFromFixture(path: jsonPath)

    // 레코드 수 계산
    let models = try await FixtureLoader.loadFlat(from: jsonPath)
    let countFormatted = String(format: "%,d", models.count)

    print("   Records loaded: \(countFormatted)")
    print("   Loading time: \(duration)")
    print("   Path: \(dbPath)")
}

/// CoreData DB 생성
@MainActor
private func generateCoreDataDB(jsonPath: String, fixturesPath: String, suffix: String) async throws {
    let dbName = "CoreDataFixture_\(suffix)"
    let searcher = CoreDataSearcher(dbName: dbName)

    try searcher.initializeDB()
    let duration = try await searcher.loadFromFixture(path: jsonPath)

    // 레코드 수 계산
    let models = try await FixtureLoader.loadFlat(from: jsonPath)
    let countFormatted = String(format: "%,d", models.count)

    print("   Records loaded: \(countFormatted)")
    print("   Loading time: \(duration)")

    // CoreData는 Application Support에 저장됨
    let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    print("   Path: \(appSupport.path)/\(dbName).sqlite")
}

/// SwiftData DB 생성
@MainActor
private func generateSwiftDataDB(jsonPath: String, fixturesPath: String, suffix: String) async throws {
    let searcher = SwiftDataSearcher()

    try searcher.initializeDB()
    let duration = try await searcher.loadFromFixture(path: jsonPath)

    // 레코드 수 계산
    let models = try await FixtureLoader.loadFlat(from: jsonPath)
    let countFormatted = String(format: "%,d", models.count)

    print("   Records loaded: \(countFormatted)")
    print("   Loading time: \(duration)")
    print("   Path: default.store (SwiftData default location)")
}

/// UserDefaults 생성
@MainActor
private func generateUserDefaultsDB(jsonPath: String, suffix: String) async throws {
    let searcher = UserDefaultsSearcher(suiteName: "com.dbperformance.fixture_\(suffix)")

    try searcher.initializeDB()
    let duration = try await searcher.loadFromFixture(path: jsonPath)

    // 레코드 수 계산
    let models = try await FixtureLoader.loadFlat(from: jsonPath)
    let countFormatted = String(format: "%,d", models.count)

    print("   Records loaded: \(countFormatted)")
    print("   Loading time: \(duration)")
    print("   Suite: com.dbperformance.fixture_\(suffix)")
}
