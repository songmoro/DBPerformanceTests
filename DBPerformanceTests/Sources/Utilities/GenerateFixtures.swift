//
//  GenerateFixtures.swift
//  DBPerformanceTests
//
//  Fixture 생성 유틸리티
//  JSON + 4개 DB 파일 생성
//

import Foundation

/// Fixture 생성 실행 함수
/// - JSON 파일 생성
/// - Realm, CoreData, SwiftData, UserDefaults DB 파일 생성
@MainActor
func generateFixtures() async {
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

    let flatJsonPath = "\(fixturesPath)/flat-1m.json"

    // Step 1: JSON Fixture 생성
    print("\n=== Step 1/5: Generating JSON Fixture ===")
    print("Path: \(flatJsonPath)")
    print("This will take ~2-5 minutes...\n")

    var generator = FixtureGenerator(seed: 42)

    do {
        try generator.generateFlatFixture(to: flatJsonPath, count: 1_000_000)
        print("✅ JSON fixture created\n")
    } catch {
        print("❌ ERROR: Failed to generate JSON fixture: \(error)")
        return
    }

    // Step 2: Realm DB 생성
    print("\n=== Step 2/5: Generating Realm DB ===")
    do {
        try await generateRealmDB(jsonPath: flatJsonPath, fixturesPath: fixturesPath)
        print("✅ Realm DB created\n")
    } catch {
        print("❌ ERROR: Failed to generate Realm DB: \(error)")
    }

    // Step 3: CoreData DB 생성
    print("\n=== Step 3/5: Generating CoreData DB ===")
    do {
        try await generateCoreDataDB(jsonPath: flatJsonPath, fixturesPath: fixturesPath)
        print("✅ CoreData DB created\n")
    } catch {
        print("❌ ERROR: Failed to generate CoreData DB: \(error)")
    }

    // Step 4: SwiftData DB 생성
    print("\n=== Step 4/5: Generating SwiftData DB ===")
    do {
        try await generateSwiftDataDB(jsonPath: flatJsonPath, fixturesPath: fixturesPath)
        print("✅ SwiftData DB created\n")
    } catch {
        print("❌ ERROR: Failed to generate SwiftData DB: \(error)")
    }

    // Step 5: UserDefaults 생성
    print("\n=== Step 5/5: Generating UserDefaults ===")
    do {
        try await generateUserDefaultsDB(jsonPath: flatJsonPath)
        print("✅ UserDefaults created\n")
    } catch {
        print("❌ ERROR: Failed to generate UserDefaults: \(error)")
    }

    print("\n🎉 All fixtures generated successfully!")
    print("   JSON: \(flatJsonPath)")
    print("   Realm: \(fixturesPath)/realm_1m.realm")
    print("   CoreData: \(fixturesPath)/coredata_1m.sqlite")
    print("   SwiftData: \(fixturesPath)/swiftdata_1m.sqlite")
    print("   UserDefaults: fixture_1m suite")
}

// MARK: - DB Generation Functions

/// Realm DB 생성
@MainActor
private func generateRealmDB(jsonPath: String, fixturesPath: String) async throws {
    let dbPath = "\(fixturesPath)/realm_1m.realm"
    let searcher = RealmSearcher(dbPath: dbPath)

    try searcher.initializeDB()
    _ = try await searcher.loadFromFixture(path: jsonPath)

    print("   Records loaded: 1,000,000")
    print("   Path: \(dbPath)")
}

/// CoreData DB 생성
@MainActor
private func generateCoreDataDB(jsonPath: String, fixturesPath: String) async throws {
    let dbName = "CoreDataFixture"
    let searcher = CoreDataSearcher(dbName: dbName)

    try searcher.initializeDB()
    _ = try await searcher.loadFromFixture(path: jsonPath)

    print("   Records loaded: 1,000,000")

    // CoreData는 Application Support에 저장됨
    let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    print("   Path: \(appSupport.path)/\(dbName).sqlite")
}

/// SwiftData DB 생성
@MainActor
private func generateSwiftDataDB(jsonPath: String, fixturesPath: String) async throws {
    let searcher = SwiftDataSearcher()

    try searcher.initializeDB()
    _ = try await searcher.loadFromFixture(path: jsonPath)

    print("   Records loaded: 1,000,000")
    print("   Path: default.store (SwiftData default location)")
}

/// UserDefaults 생성
@MainActor
private func generateUserDefaultsDB(jsonPath: String) async throws {
    let searcher = UserDefaultsSearcher(suiteName: "com.dbperformance.fixture_1m")

    try searcher.initializeDB()
    _ = try await searcher.loadFromFixture(path: jsonPath)

    print("   Records loaded: 1,000,000")
    print("   Suite: com.dbperformance.fixture_1m")
}
