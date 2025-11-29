import Foundation

/// 벤치마크 결과 저장 구조
struct BenchmarkResult: Codable {
    let metadata: Metadata
    let results: [DataStageResult]

    struct Metadata: Codable {
        let timestamp: Date
        let databaseName: String
        let databaseVersion: String
        let environment: EnvironmentInfo
    }

    struct EnvironmentInfo: Codable {
        // 하드웨어
        let cpuModel: String
        let cpuCores: Int
        let ramSize: Double // GB
        let diskType: String

        // 소프트웨어
        let macOSVersion: String
        let swiftVersion: String
        let xcodeVersion: String

        // 리소스 상태
        let cpuUsage: Double // %
        let memoryUsage: Double // %
        let diskUsage: Double // %
    }

    struct DataStageResult: Codable {
        let dataSize: Int // 1000, 10000, 100000, 1000000
        let measurements: TestMeasurements
    }

    struct TestMeasurements: Codable {
        let initialization: Double? // ms (첫 단계만)
        let create: Double // ms
        let batchCreate: Double // ms
        let read: Double // ms
        let indexedSearch: Double // ms
        let nonIndexedSearch: Double // ms
        let complexQuery: Double // ms
        let update: Double // ms
        let transaction: Double // ms
        let concurrency: Double // ms
        let delete: Double? // ms (마지막 단계만)
    }
}

extension BenchmarkResult {
    /// JSON 파일로 저장
    func save(to directory: URL) throws {
        let formatter = ISO8601DateFormatter()
        let timestamp = formatter.string(from: metadata.timestamp)
        let filename = "\(timestamp)-\(metadata.databaseName).json"
        let fileURL = directory.appendingPathComponent(filename)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(self)
        try data.write(to: fileURL)
    }

    /// JSON 파일에서 로드
    static func load(from fileURL: URL) throws -> BenchmarkResult {
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(BenchmarkResult.self, from: data)
    }
}

/// Duration을 밀리초로 변환
extension Duration {
    nonisolated var milliseconds: Double {
        let components = self.components
        return Double(components.seconds) * 1000.0 + Double(components.attoseconds) / 1_000_000_000_000_000.0
    }
}
