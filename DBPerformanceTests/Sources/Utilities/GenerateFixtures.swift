//
//  GenerateFixtures.swift
//  DBPerformanceTests
//
//  Fixture 생성 유틸리티
//  JSON + 4개 DB 파일 생성
//  [CR-74] FixtureGenerationConfig enum 기반 생성 권장
//

import Foundation

// MARK: - Helper Functions

/// 숫자를 천 단위 구분자로 포맷팅 (로케일 독립적)
private func formatNumber(_ number: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.groupingSeparator = ","
    formatter.locale = Locale(identifier: "en_US")
    return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
}

/// Fixture 생성 실행 함수 (100K 데이터)
/// - JSON 파일 생성
/// - Realm, CoreData, SwiftData, UserDefaults DB 파일 생성
/// - **권장**: `FixtureGenerationConfig.flat100k` 사용
@MainActor
func generateFixtures() async {
    // FixtureGenerationConfig.flat100k와 동일
    await generateFixturesWithCount(100_000, suffix: "100k")
}

/// Fixture 생성 실행 함수 (1M 데이터)
/// - JSON 파일 생성
/// - Realm, CoreData, SwiftData DB 파일 생성 (UserDefaults 제외)
/// - **권장**: `FixtureGenerationConfig.flat1m` 사용
@MainActor
func generateFixtures1M() async {
    // FixtureGenerationConfig.flat1m과 동일
    await generateFixturesWithCount(1_000_000, suffix: "1m")
}

/// Relational Fixture 생성 실행 함수 (100K 데이터)
/// - ProductRecord + Tags 1:N 관계
/// - Realm, CoreData, SwiftData DB 파일 생성
/// - **권장**: `FixtureGenerationConfig.relational100k` 사용
@MainActor
func generateRelationalFixtures() async {
    // FixtureGenerationConfig.relational100k와 동일
    await generateRelationalFixturesWithCount(100_000, suffix: "100k")
}

/// Relational Fixture 생성 실행 함수 (1M 데이터)
/// - ProductRecord + Tags 1:N 관계
/// - Realm, CoreData, SwiftData DB 파일 생성
/// - **권장**: `FixtureGenerationConfig.relational1m` 사용
@MainActor
func generateRelationalFixtures1M() async {
    // FixtureGenerationConfig.relational1m과 동일
    await generateRelationalFixturesWithCount(1_000_000, suffix: "1m")
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
    let countFormatted = formatNumber(count)

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
    let countFormatted = formatNumber(models.count)

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
    let countFormatted = formatNumber(models.count)

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
    let countFormatted = formatNumber(models.count)

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
    let countFormatted = formatNumber(models.count)

    print("   Records loaded: \(countFormatted)")
    print("   Loading time: \(duration)")
    print("   Suite: com.dbperformance.fixture_\(suffix)")
}

// MARK: - Relational Fixtures Generation

/// Relational Fixture 생성 공통 함수
/// - Parameter count: 생성할 데이터 개수
/// - Parameter suffix: 파일명 접미사 (100k, 1m 등)
@MainActor
private func generateRelationalFixturesWithCount(_ count: Int, suffix: String) async {
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

    let relationalJsonPath = "\(fixturesPath)/relational-\(suffix).json"
    let countFormatted = formatNumber(count)

    // Step 1: JSON Fixture 생성
    print("\n=== Step 1/4: Generating Relational JSON Fixture (\(countFormatted) records) ===")
    print("Path: \(relationalJsonPath)")
    if count >= 1_000_000 {
        print("This will take ~5-10 minutes...\n")
    } else {
        print("This will take ~30-60 seconds...\n")
    }

    var generator = FixtureGenerator(seed: 42)

    do {
        try generator.generateRelationalFixture(to: relationalJsonPath, count: count)
        print("✅ Relational JSON fixture created\n")
    } catch {
        print("❌ ERROR: Failed to generate relational JSON fixture: \(error)")
        return
    }

    // Step 2: Realm DB 생성
    print("\n=== Step 2/4: Generating Realm Relational DB ===")
    do {
        try await generateRealmRelationalDB(jsonPath: relationalJsonPath, fixturesPath: fixturesPath, suffix: suffix)
        print("✅ Realm Relational DB created\n")
    } catch {
        print("❌ ERROR: Failed to generate Realm Relational DB: \(error)")
    }

    // Step 3: CoreData DB 생성
    print("\n=== Step 3/4: Generating CoreData Relational DB ===")
    do {
        try await generateCoreDataRelationalDB(jsonPath: relationalJsonPath, fixturesPath: fixturesPath, suffix: suffix)
        print("✅ CoreData Relational DB created\n")
    } catch {
        print("❌ ERROR: Failed to generate CoreData Relational DB: \(error)")
    }

    // Step 4: SwiftData DB 생성
    print("\n=== Step 4/4: Generating SwiftData Relational DB ===")
    do {
        try await generateSwiftDataRelationalDB(jsonPath: relationalJsonPath, fixturesPath: fixturesPath, suffix: suffix)
        print("✅ SwiftData Relational DB created\n")
    } catch {
        print("❌ ERROR: Failed to generate SwiftData Relational DB: \(error)")
    }

    print("\n🎉 All relational fixtures generated successfully!")
    print("   JSON: \(relationalJsonPath)")
    print("   Realm: \(fixturesPath)/realm_relational_\(suffix).realm")
    print("   CoreData: Application Support/CoreDataRelationalFixture_\(suffix).sqlite")
    print("   SwiftData: default.store (SwiftData default location)")
}

/// Realm Relational DB 생성
@MainActor
private func generateRealmRelationalDB(jsonPath: String, fixturesPath: String, suffix: String) async throws {
    let dbPath = "\(fixturesPath)/realm_relational_\(suffix).realm"
    let searcher = RealmRelationalSearcher(dbPath: dbPath)

    try searcher.initializeDB()
    let duration = try await searcher.loadFromFixture(path: jsonPath)

    let models = try await RelationalFixtureLoader.loadRelational(from: jsonPath)
    let countFormatted = formatNumber(models.count)

    print("   Records loaded: \(countFormatted)")
    print("   Loading time: \(duration)")
    print("   Path: \(dbPath)")
}

/// CoreData Relational DB 생성
@MainActor
private func generateCoreDataRelationalDB(jsonPath: String, fixturesPath: String, suffix: String) async throws {
    let dbName = "CoreDataRelationalFixture_\(suffix)"
    let searcher = CoreDataRelationalSearcher(dbName: dbName)

    try searcher.initializeDB()
    let duration = try await searcher.loadFromFixture(path: jsonPath)

    let models = try await RelationalFixtureLoader.loadRelational(from: jsonPath)
    let countFormatted = formatNumber(models.count)

    print("   Records loaded: \(countFormatted)")
    print("   Loading time: \(duration)")

    let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    print("   Path: \(appSupport.path)/\(dbName).sqlite")
}

/// SwiftData Relational DB 생성
@MainActor
private func generateSwiftDataRelationalDB(jsonPath: String, fixturesPath: String, suffix: String) async throws {
    let searcher = SwiftDataRelationalSearcher()

    try searcher.initializeDB()
    let duration = try await searcher.loadFromFixture(path: jsonPath)

    let models = try await RelationalFixtureLoader.loadRelational(from: jsonPath)
    let countFormatted = formatNumber(models.count)

    print("   Records loaded: \(countFormatted)")
    print("   Loading time: \(duration)")
    print("   Path: default.store (SwiftData default location)")
}
