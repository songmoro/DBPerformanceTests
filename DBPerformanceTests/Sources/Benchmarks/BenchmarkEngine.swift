import Foundation

/// 벤치마크 실행 엔진
actor BenchmarkEngine<Adapter: DatabaseAdapter> {
    nonisolated(unsafe) private let adapter: Adapter
    private let clock = ContinuousClock()

    init(adapter: Adapter) {
        self.adapter = adapter
    }

    /// 단일 작업 시간 측정
    func measure(_ operation: () async throws -> Void) async throws -> Duration {
        let duration = try await clock.measure {
            try await operation()
        }
        return duration
    }

    /// TM-09: 초기 로딩
    func benchmarkInitialization() async throws -> Duration {
        return try await measure {
            try await adapter.initialize()
        }
    }

    /// TM-10: Create (개별 순차 생성)
    func benchmarkCreate(models: [Adapter.Model]) async throws -> Duration {
        return try await measure {
            for model in models {
                try await adapter.create(model)
            }
        }
    }

    /// TM-11: 배치 작업
    func benchmarkBatchCreate(models: [Adapter.Model]) async throws -> Duration {
        return try await measure {
            try await adapter.createBatch(models)
        }
    }

    /// TM-12: Read (단순 조회)
    func benchmarkRead(ids: [String]) async throws -> Duration {
        return try await measure {
            for id in ids {
                _ = try await adapter.read(id: id)
            }
        }
    }

    /// TM-13: 색인 검색
    func benchmarkIndexedSearch(field: String, value: Any, iterations: Int) async throws -> Duration {
        return try await measure {
            for _ in 0..<iterations {
                _ = try await adapter.searchIndexed(field: field, value: value)
            }
        }
    }

    /// TM-14: 비색인 검색
    func benchmarkNonIndexedSearch(field: String, value: Any, iterations: Int) async throws -> Duration {
        return try await measure {
            for _ in 0..<iterations {
                _ = try await adapter.searchNonIndexed(field: field, value: value)
            }
        }
    }

    /// TM-15: 쿼리 복잡도별 성능
    func benchmarkComplexQuery(iterations: Int) async throws -> Duration {
        return try await measure {
            for _ in 0..<iterations {
                _ = try await adapter.executeComplexQuery()
            }
        }
    }

    /// TM-16: Update
    func benchmarkUpdate(ids: [String], updates: [String: Any]) async throws -> Duration {
        return try await measure {
            for id in ids {
                try await adapter.update(id: id, updates: updates)
            }
        }
    }

    /// TM-17: 트랜잭션 처리
    func benchmarkTransaction(operations: @Sendable () async throws -> Void) async throws -> Duration {
        return try await measure {
            try await adapter.executeTransaction(operations: operations)
        }
    }

    /// TM-18: 동시성 처리
    func benchmarkConcurrency(operations: [@Sendable () async throws -> Void]) async throws -> Duration {
        return try await measure {
            try await adapter.executeConcurrent(operations: operations)
        }
    }

    /// TM-19: Delete
    func benchmarkDelete(ids: [String]) async throws -> Duration {
        return try await measure {
            for id in ids {
                try await adapter.delete(id: id)
            }
        }
    }

    /// Cleanup
    func cleanup() async throws {
        try await adapter.cleanup()
    }

    /// Flush pending changes (for batching optimization)
    func flush() async throws {
        // CoreDataAdapter에만 있는 메서드이지만 프로토콜 확장으로 처리 가능
        if let flushable = adapter as? any FlushableAdapter {
            try await flushable.flush()
        }
    }
}
