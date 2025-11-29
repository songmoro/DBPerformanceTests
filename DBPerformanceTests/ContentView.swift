import SwiftUI

@MainActor
struct ContentView: View {
    @State private var isRunning = false
    @State private var currentDatabase = ""
    @State private var logMessages: [String] = []
    @State private var selectedDatabase: DatabaseType = .userDefaults
    @State private var selectedModel: ModelType = .simple
    @State private var selectedDataSize: DataSize = .hundred_k

    enum DatabaseType: String, CaseIterable {
        case userDefaults = "UserDefaults"
        case swiftData = "SwiftData"
        case coreData = "CoreData"
        case realm = "Realm"
    }

    enum ModelType: String, CaseIterable {
        case simple = "Simple"
        case complex = "Complex"
        case search = "Search"
    }

    enum DataSize: String, CaseIterable {
        case hundred_k = "100K"
        case one_m = "1M"

        var suffix: String {
            switch self {
            case .hundred_k: return "100k"
            case .one_m: return "1m"
            }
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Database Performance Tests")
                .font(.largeTitle)
                .bold()

            VStack(spacing: 10) {
                Picker("Select Database", selection: $selectedDatabase) {
                    ForEach(DatabaseType.allCases, id: \.self) { db in
                        Text(db.rawValue).tag(db)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(isRunning)

                Picker("Select Model", selection: $selectedModel) {
                    ForEach(ModelType.allCases, id: \.self) { model in
                        Text(model.rawValue).tag(model)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(isRunning)

                if selectedModel == .search {
                    Picker("Data Size", selection: $selectedDataSize) {
                        ForEach(DataSize.allCases, id: \.self) { size in
                            Text(size.rawValue).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(isRunning)
                }
            }

            HStack(spacing: 15) {
                Button("Run Benchmark") {
                    Task {
                        await runBenchmark()
                    }
                }
                .disabled(isRunning)
                .buttonStyle(.borderedProminent)

                Button("Run All") {
                    Task {
                        await runAllBenchmarks()
                    }
                }
                .disabled(isRunning)
                .buttonStyle(.bordered)

                if selectedModel == .search {
                    Button("Generate Fixtures") {
                        Task {
                            await generateFixturesUI()
                        }
                    }
                    .disabled(isRunning)
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }

                Button("Clear Logs") {
                    logMessages.removeAll()
                }
                .disabled(isRunning)
                .buttonStyle(.bordered)
            }

            if isRunning {
                ProgressView("Running: \(currentDatabase) [\(selectedModel.rawValue)Model]")
                    .padding()
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(Array(logMessages.enumerated()), id: \.offset) { _, message in
                        Text(message)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .frame(maxHeight: .infinity)
            .background(Color(.textBackgroundColor))
            .cornerRadius(8)
        }
        .padding()
        .frame(minWidth: 800, minHeight: 600)
    }

    private func runBenchmark() async {
        guard !isRunning else { return }

        isRunning = true
        currentDatabase = selectedDatabase.rawValue
        log("=== Starting benchmark for \(selectedDatabase.rawValue) [\(selectedModel.rawValue)Model] ===")

        do {
            switch selectedModel {
            case .simple:
                try await runSimpleModelBenchmark()
            case .complex:
                try await runComplexModelBenchmark()
            case .search:
                try await runSearchBenchmark()
            }

            log("=== Benchmark completed successfully ===\n")
        } catch {
            log("ERROR: \(error.localizedDescription)")
        }

        isRunning = false
        currentDatabase = ""
    }

    private func runAllBenchmarks() async {
        for dbType in DatabaseType.allCases {
            selectedDatabase = dbType
            for modelType in ModelType.allCases {
                selectedModel = modelType
                await runBenchmark()

                // 벤치마크 간 대기
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    // MARK: - SimpleModel Benchmarks

    private func runSimpleModelBenchmark() async throws {
        switch selectedDatabase {
        case .userDefaults:
            let adapter = UserDefaultsAdapter(suiteName: "com.dbtest.userdefaults.simple")
            let orchestrator = SimpleBenchmarkOrchestrator(adapter: adapter)
            let result = try await orchestrator.runFullBenchmark()
            try saveAndLog(result: result)

        case .swiftData:
            let adapter = SwiftDataAdapter()
            let orchestrator = SimpleBenchmarkOrchestrator(adapter: adapter)
            let result = try await orchestrator.runFullBenchmark()
            try saveAndLog(result: result)

        case .coreData:
            let adapter = CoreDataAdapter()
            let orchestrator = SimpleBenchmarkOrchestrator(adapter: adapter)
            let result = try await orchestrator.runFullBenchmark()
            try saveAndLog(result: result)

        case .realm:
            let adapter = RealmAdapter()
            let orchestrator = SimpleBenchmarkOrchestrator(adapter: adapter)
            let result = try await orchestrator.runFullBenchmark()
            try saveAndLog(result: result)
        }
    }

    // MARK: - Fixture Generation

    private func generateFixturesUI() async {
        guard !isRunning else { return }

        isRunning = true
        currentDatabase = "Fixture Generator"
        log("=== Generating Fixture Files ===")
        log("This may take several minutes...")

        await generateFixtures()

        isRunning = false
        currentDatabase = ""
    }

    // MARK: - Search Benchmarks

    private func runSearchBenchmark() async throws {
        // DB 파일 존재 확인
        let dbPath = getDBPath(for: selectedDatabase)

        if !checkDBExists(for: selectedDatabase) {
            log("ERROR: DB file not found for \(selectedDatabase.rawValue)")
            log("Please generate fixtures first using 'Generate Fixtures' button")
            throw SearchBenchmarkError.dbNotFound(database: selectedDatabase.rawValue)
        }

        log("Using \(selectedDatabase.rawValue) DB: \(dbPath)")

        let orchestrator = SearchOrchestrator()

        switch selectedDatabase {
        case .realm:
            let report = try await orchestrator.runRealmBenchmark(fixturePath: "")
            try saveAndLogSearchReport(report: report)

        case .coreData:
            let report = try await orchestrator.runCoreDataBenchmark(fixturePath: "")
            try saveAndLogSearchReport(report: report)

        case .swiftData:
            let report = try await orchestrator.runSwiftDataBenchmark(fixturePath: "")
            try saveAndLogSearchReport(report: report)

        case .userDefaults:
            let report = try await orchestrator.runUserDefaultsBenchmark(fixturePath: "")
            try saveAndLogSearchReport(report: report)
        }
    }

    // MARK: - ComplexModel Benchmarks

    private func runComplexModelBenchmark() async throws {
        switch selectedDatabase {
        case .userDefaults:
            let adapter = UserDefaultsComplexAdapter(suiteName: "com.dbtest.userdefaults.complex")
            let orchestrator = ComplexBenchmarkOrchestrator(adapter: adapter)
            let result = try await orchestrator.runFullBenchmark()
            try saveAndLog(result: result)

        case .swiftData:
            let adapter = SwiftDataComplexAdapter()
            let orchestrator = ComplexBenchmarkOrchestrator(adapter: adapter)
            let result = try await orchestrator.runFullBenchmark()
            try saveAndLog(result: result)

        case .coreData:
            let adapter = CoreDataComplexAdapter()
            let orchestrator = ComplexBenchmarkOrchestrator(adapter: adapter)
            let result = try await orchestrator.runFullBenchmark()
            try saveAndLog(result: result)

        case .realm:
            let adapter = RealmComplexAdapter()
            let orchestrator = ComplexBenchmarkOrchestrator(adapter: adapter)
            let result = try await orchestrator.runFullBenchmark()
            try saveAndLog(result: result)
        }
    }

    private func saveAndLog(result: BenchmarkResult) throws {
        let resultsDir = getResultsDirectory()
        try result.save(to: resultsDir)

        log("Results saved to: \(resultsDir.path)")
        logResultSummary(result)
    }

    private func getResultsDirectory() -> URL {
        let fileManager = FileManager.default
        let projectDir = fileManager.currentDirectoryPath
        let resultsPath = "\(projectDir)/Results"

        // Results 디렉토리 생성
        if !fileManager.fileExists(atPath: resultsPath) {
            try? fileManager.createDirectory(atPath: resultsPath, withIntermediateDirectories: true)
        }

        return URL(fileURLWithPath: resultsPath)
    }

    private func logResultSummary(_ result: BenchmarkResult) {
        log("\nSummary:")
        log("  Database: \(result.metadata.databaseName)")
        log("  Version: \(result.metadata.databaseVersion)")
        log("  CPU: \(result.metadata.environment.cpuModel)")
        log("  RAM: \(String(format: "%.2f GB", result.metadata.environment.ramSize))")

        for stage in result.results {
            log("\n  Data Size: \(stage.dataSize)")
            if let initialization = stage.measurements.initialization {
                log("    Initialization: \(String(format: "%.2f ms", initialization))")
            }
            log("    Create: \(String(format: "%.2f ms", stage.measurements.create))")
            log("    Batch: \(String(format: "%.2f ms", stage.measurements.batchCreate))")
            log("    Read: \(String(format: "%.2f ms", stage.measurements.read))")
            log("    Update: \(String(format: "%.2f ms", stage.measurements.update))")

            if let delete = stage.measurements.delete {
                log("    Delete: \(String(format: "%.2f ms", delete))")
            }
        }
    }

    private func log(_ message: String) {
        logMessages.append(message)
        print(message)
    }

    // MARK: - Search Report Helpers

    private func getFixturesDirectory() -> String {
        let projectDir = FileManager.default.currentDirectoryPath
        return "\(projectDir)/Sources/Fixtures"
    }

    private func getDBPath(for database: DatabaseType) -> String {
        let fixturesDir = getFixturesDirectory()

        switch database {
        case .realm:
            return "\(fixturesDir)/realm_100k.realm"
        case .coreData:
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            return "\(appSupport.path)/CoreDataFixture.sqlite"
        case .swiftData:
            return "default.store (SwiftData default location)"
        case .userDefaults:
            return "com.dbperformance.fixture_100k (UserDefaults suite)"
        }
    }

    private func checkDBExists(for database: DatabaseType) -> Bool {
        switch database {
        case .realm:
            let fixturesDir = getFixturesDirectory()
            let dbPath = "\(fixturesDir)/realm_100k.realm"
            return FileManager.default.fileExists(atPath: dbPath)

        case .coreData:
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            let dbPath = appSupport.appendingPathComponent("CoreDataFixture.sqlite")
            return FileManager.default.fileExists(atPath: dbPath.path)

        case .swiftData:
            // SwiftData는 자동으로 생성되므로 항상 true
            return true

        case .userDefaults:
            // UserDefaults 데이터 존재 확인
            let defaults = UserDefaults(suiteName: "com.dbperformance.fixture_100k")
            return defaults?.data(forKey: "flat_models_storage") != nil
        }
    }

    private func saveAndLogSearchReport(report: SearchBenchmarkReport) throws {
        let resultsDir = getResultsDirectory()
        try report.save(to: resultsDir)

        log("Results saved to: \(resultsDir.path)")
        logSearchReportSummary(report)
    }

    private func logSearchReportSummary(_ report: SearchBenchmarkReport) {
        log("\nSearch Benchmark Summary:")
        log("  Database: \(report.metadata.databaseName)")
        log("  Version: \(report.metadata.databaseVersion)")
        log("  Fixture Load Time: \(String(format: "%.2f ms", report.fixtureLoadTimeMs))")
        log("\n  Search Results:")

        for result in report.searchResults {
            log("    [\(result.scenario)] \(result.queryCondition ?? "")")
            log("      Response Time: \(String(format: "%.2f ms", result.responseTimeMs))")
            log("      Result Count: \(result.resultCount)")
            log("      Indexed: \(result.indexed)")
        }
    }
}

// MARK: - Search Benchmark Error

enum SearchBenchmarkError: Error, CustomStringConvertible {
    case dbNotFound(database: String)

    var description: String {
        switch self {
        case .dbNotFound(let database):
            return "\(database) DB not found. Please generate fixtures first."
        }
    }
}


#Preview {
    ContentView()
}
