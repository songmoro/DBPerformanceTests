import Foundation

/// ComplexModel 전용 벤치마크 오케스트레이터
actor ComplexBenchmarkOrchestrator<Adapter: DatabaseAdapter> where Adapter.Model == ComplexModel {
    private let adapter: Adapter
    private let engine: BenchmarkEngine<Adapter>
    private let dataSizes = [1_000, 10_000, 100_000]

    init(adapter: Adapter) {
        self.adapter = adapter
        self.engine = BenchmarkEngine(adapter: adapter)
    }

    /// 전체 벤치마크 실행
    func runFullBenchmark() async throws -> BenchmarkResult {
        print("Starting benchmark for \(adapter.name) [ComplexModel]...")

        var stageResults: [BenchmarkResult.DataStageResult] = []
        var initializationTime: Double?

        // TM-09: 초기 로딩 (첫 단계만)
        let initDuration = try await engine.benchmarkInitialization()
        initializationTime = initDuration.milliseconds
        print("  Initialization: \(initializationTime!)ms")

        // 각 데이터 단계별 테스트
        for (index, dataSize) in dataSizes.enumerated() {
            print("\n  Testing with \(dataSize) records...")

            let isFirstStage = (index == 0)
            let measurements = try await runStage(
                dataSize: dataSize,
                isFirstStage: isFirstStage,
                initTime: isFirstStage ? initializationTime : nil
            )

            let stageResult = BenchmarkResult.DataStageResult(
                dataSize: dataSize,
                measurements: measurements
            )
            stageResults.append(stageResult)
        }

        // TM-19: 최종 Delete 테스트
        print("\n  Running final delete test...")
        let allIDs = (0..<dataSizes.last!).map { "id-\($0)" }
        let deleteDuration = try await engine.benchmarkDelete(ids: allIDs)
        print("  Delete: \(deleteDuration.milliseconds)ms")

        // 마지막 결과에 delete 추가
        if var lastResult = stageResults.last {
            var measurements = lastResult.measurements
            measurements = BenchmarkResult.TestMeasurements(
                initialization: measurements.initialization,
                create: measurements.create,
                batchCreate: measurements.batchCreate,
                read: measurements.read,
                indexedSearch: measurements.indexedSearch,
                nonIndexedSearch: measurements.nonIndexedSearch,
                complexQuery: measurements.complexQuery,
                update: measurements.update,
                transaction: measurements.transaction,
                concurrency: measurements.concurrency,
                delete: deleteDuration.milliseconds
            )
            stageResults[stageResults.count - 1] = BenchmarkResult.DataStageResult(
                dataSize: lastResult.dataSize,
                measurements: measurements
            )
        }

        // Cleanup
        try await engine.cleanup()
        print("\nBenchmark completed for \(adapter.name) [ComplexModel]")

        // 결과 생성
        let metadata = BenchmarkResult.Metadata(
            timestamp: Date(),
            databaseName: adapter.name,
            databaseVersion: adapter.version,
            environment: EnvironmentCollector.collect()
        )

        return BenchmarkResult(metadata: metadata, results: stageResults)
    }

    private func runStage(dataSize: Int, isFirstStage: Bool, initTime: Double?) async throws -> BenchmarkResult.TestMeasurements {
        // 이전 단계 데이터 개수 계산
        let previousSize = isFirstStage ? 0 : dataSize / 10
        let newDataCount = dataSize - previousSize

        // 새로 추가할 데이터 생성
        let newModels = (previousSize..<dataSize).map { index in
            ComplexModelGenerator.generate(id: "id-\(index)", index: index)
        }

        // TM-10: Create
        let createDuration = try await engine.benchmarkCreate(models: newModels)
        print("    Create (\(newDataCount) records): \(createDuration.milliseconds)ms")

        // TM-11: Batch Create
        let batchModels = ComplexModelGenerator.generateBatch(
            prefix: "batch-\(dataSize)",
            count: min(100, newDataCount),
            startIndex: 0
        )
        let batchDuration = try await engine.benchmarkBatchCreate(models: batchModels)
        print("    Batch Create: \(batchDuration.milliseconds)ms")

        // TM-12: Read
        let readIDs = (0..<min(100, dataSize)).map { "id-\($0)" }
        let readDuration = try await engine.benchmarkRead(ids: readIDs)
        print("    Read: \(readDuration.milliseconds)ms")

        // TM-13: Indexed Search
        let indexedDuration = try await engine.benchmarkIndexedSearch(field: "value", value: 500, iterations: 10)
        print("    Indexed Search: \(indexedDuration.milliseconds)ms")

        // TM-14: Non-Indexed Search
        let nonIndexedDuration = try await engine.benchmarkNonIndexedSearch(field: "name", value: "ComplexName 100", iterations: 10)
        print("    Non-Indexed Search: \(nonIndexedDuration.milliseconds)ms")

        // TM-15: Complex Query
        let complexDuration = try await engine.benchmarkComplexQuery(iterations: 10)
        print("    Complex Query: \(complexDuration.milliseconds)ms")

        // TM-16: Update
        let updateIDs = (0..<min(100, dataSize)).map { "id-\($0)" }
        let updateDuration = try await engine.benchmarkUpdate(ids: updateIDs, updates: ComplexModelGenerator.getUpdateFields())
        print("    Update: \(updateDuration.milliseconds)ms")

        // TM-17: Transaction
        let transactionDuration = try await engine.benchmarkTransaction { @Sendable in
            let model = ComplexModelGenerator.generate(id: "tx-\(dataSize)", index: 9999)
            try await self.adapter.create(model)
            try await self.adapter.update(id: model.id, updates: ["value": 8888])
        }
        print("    Transaction: \(transactionDuration.milliseconds)ms")

        // TM-18: Concurrency
        let concurrentOps: [@Sendable () async throws -> Void] = (0..<10).map { index in
            { @Sendable in
                let model = ComplexModelGenerator.generateConcurrent(prefix: "concurrent-\(dataSize)", index: index)
                try await self.adapter.create(model)
            }
        }
        let concurrencyDuration = try await engine.benchmarkConcurrency(operations: concurrentOps)
        print("    Concurrency: \(concurrencyDuration.milliseconds)ms")

        return BenchmarkResult.TestMeasurements(
            initialization: initTime,
            create: createDuration.milliseconds,
            batchCreate: batchDuration.milliseconds,
            read: readDuration.milliseconds,
            indexedSearch: indexedDuration.milliseconds,
            nonIndexedSearch: nonIndexedDuration.milliseconds,
            complexQuery: complexDuration.milliseconds,
            update: updateDuration.milliseconds,
            transaction: transactionDuration.milliseconds,
            concurrency: concurrencyDuration.milliseconds,
            delete: nil
        )
    }
}
